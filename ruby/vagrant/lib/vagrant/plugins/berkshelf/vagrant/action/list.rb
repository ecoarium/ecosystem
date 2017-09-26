require 'berkshelf/smart'
require 'logging-helper'
require 'pp'

module Berkshelf
  module Vagrant
    module Action
      # @author Jamie Winsor <jamie@vialstudios.com>
      class List
        include Berkshelf::Vagrant::EnvHelpers
        include LoggingHelper::LogToTerminal

        def initialize(app, env)
          @app = app
        end

        def call(env)
          unless berkshelf_enabled?(env)
            env[:berkshelf].ui.info "skipping berkshelf, it's not enabled"
            return @app.call(env)
          end

          unless chef_solo?(env)
            env[:berkshelf].ui.info "skipping berkshelf, chef-solo is not a provisioner"
            return @app.call(env)
          end

          Berkshelf::Vagrant::Config.instance = env[:machine].config.berkshelf

          debug { env[:machine].config.berkshelf.pretty_inspect }

          env[:berkshelf].berksfile = Berkshelf::Berksfile.from_file(env[:machine].config.berkshelf.berksfile_path, lock_file_path: File.expand_path("Berksfile.#{env[:machine].name}.lock"))
          
          env[:berkshelf].ui.info "using berksfile: #{env[:machine].config.berkshelf.berksfile_path}"

          Berkshelf.formatter.list(env[:berkshelf].berksfile.list)
          
          @app.call(env)
        end
      end
    end
  end
end
