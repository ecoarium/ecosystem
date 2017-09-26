module Berkshelf
  module Vagrant
    module Action
      # @author Jamie Winsor <jamie@vialstudios.com>
      class Clean
        include Berkshelf::Vagrant::EnvHelpers

        def initialize(app, env)
          @app = app
        end

        def call(env)
          unless berkshelf_enabled?(env)
            return @app.call(env)
          end

          env[:berkshelf].ui.info "Cleaning Vagrant's berkshelf"

          env[:berkshelf].state_file_manager.clean

          env[:berkshelf].state_file_manager = nil

          @app.call(env)
        rescue Berkshelf::BerkshelfError => e
          raise Berkshelf::VagrantWrapperError.new(e)
        end
      end
    end
  end
end
