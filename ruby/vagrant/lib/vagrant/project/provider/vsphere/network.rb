require "vagrant/project/mixins/configurable"

module Vagrant
  module Project
    module Provider
      class VSphere < Base
        module Config
          class Network
            include Vagrant::Project::Mixins::Configurable
            include LoggingHelper::LogToTerminal

            attr_config :ip_address

            def configure_this(vagrant_machine, vbox)
              vagrant_machine.vm.network "private_network", ip: ip_address
            end
          end
        end
      end
    end
  end
end