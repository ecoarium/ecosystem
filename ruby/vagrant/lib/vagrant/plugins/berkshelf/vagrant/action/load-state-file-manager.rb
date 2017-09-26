module Berkshelf
  module Vagrant
    module Action
      # @author Jamie Winsor <jamie@vialstudios.com>
      class LoadStateFileManager
        include Berkshelf::Vagrant::EnvHelpers

        def initialize(app, env)
          @app = app
        end

        def call(env)
          unless berkshelf_enabled?(env)
            return @app.call(env)
          end

          env[:berkshelf].state_file_manager = Berkshelf::Vagrant::StateFileManager.new(env[:machine].name.to_s)

          @app.call(env)
        end

        
      end
    end
  end
end
