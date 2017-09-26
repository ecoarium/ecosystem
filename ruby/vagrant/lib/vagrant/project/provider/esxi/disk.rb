require 'vagrant/project/mixins/configurable'

module Vagrant
  module Project
    module Provider
      class ESXI < Base
        module Config
          class Disk
            include Vagrant::Project::Mixins::Configurable
            include LoggingHelper::LogToTerminal

            attr_config :size, :controller_id, :port

            def configure_this(vagrant_machine, esxi)
              esxi.disk size: size, controller_id: controller_id, port: port
            end
          end
        end
      end
    end
  end
end