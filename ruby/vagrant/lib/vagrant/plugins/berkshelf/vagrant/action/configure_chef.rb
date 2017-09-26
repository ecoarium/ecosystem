module Berkshelf
  module Vagrant
    module Action
      # @author Jamie Winsor <jamie@vialstudios.com>
      class ConfigureChef
        include Berkshelf::Vagrant::EnvHelpers

        def initialize(app, env)
          @app = app
        end

        def call(env)
          unless berkshelf_enabled?(env)
            return @app.call(env)
          end

          if chef_solo?(env) && shelf = env[:berkshelf].state_file_manager.shelf_directory_path
            provisioners(:chef_solo, env).each do |provisioner|
              if !provisioner.config.cookbooks_path.is_a?(Array)
                provisioner.config.cookbooks_path = [provisioner.config.cookbooks_path, shelf]
              else
                provisioner.config.cookbooks_path << provisioner.config.send(:prepare_folders_config, shelf).first
              end
            end
          end

          @app.call(env)
        end
      end
    end
  end
end
