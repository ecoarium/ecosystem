require 'berkshelf/smart'
require 'logging-helper'
require 'facets/string'
require 'pp'

module Berkshelf
  module Vagrant
    module Action
      # @author Jamie Winsor <jamie@vialstudios.com>
      class Install
        include Berkshelf::Vagrant::EnvHelpers
        include LoggingHelper::LogToTerminal

        def initialize(app, env)
          @app = app
        end

        def call(env)
          if provision_disabled?(env)
            env[:berkshelf].ui.info "skipping berkshelf as provision is not set"
            return @app.call(env)
          end

          unless berkshelf_enabled?(env)
            env[:berkshelf].ui.info "skipping berkshelf, it's not enabled"
            return @app.call(env)
          end

          unless chef_solo?(env)
            env[:berkshelf].ui.info "skipping berkshelf, chef-solo is not a provisioner"
            return @app.call(env)
          end

          Berkshelf::Vagrant::Config.instance = env[:machine].config.berkshelf

          machine = ::Vagrant::Project.project_environment.machines[env[:machine].name]

          machine_type = machine.class.name.split('::').last.snakecase.to_sym

          env[:berkshelf].berksfile = Berkshelf::Berksfile.from_file(env[:machine].config.berkshelf.berksfile_path, lock_file_path: File.expand_path("Berksfile.#{env[:machine].name}.lock"), machine_type: machine_type)

          env[:berkshelf].ui.info "using berksfile: #{env[:machine].config.berkshelf.berksfile_path}"

          berks_flag_file_path = File.join(['.vagrant', 'machines', env[:machine].name.to_s, 'berkshelf.flag'].compact)

          smart_berks = Berkshelf::Smart.new(
            env[:berkshelf].berksfile,
            env[:berkshelf].state_file_manager.flag_file_path,
            env[:berkshelf].state_file_manager.shelf_directory_path
          )
          smart_berks.ensure_cookbooks_are_uptodate

          @app.call(env)
        end
      end
    end
  end
end
