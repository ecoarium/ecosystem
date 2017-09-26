require "vagrant/project/mixins/configurable"

module Vagrant
  module Project
    module Provider
      module LXCModule
        module Config
          class Network
            include Vagrant::Project::Mixins::Configurable
            include LoggingHelper::LogToTerminal

	      		attr_config :ip_address, :ip_gateway

            def configure_this(vagrant_machine, lxc)
              lxc.customize 'network.ipv4', ip_address unless ip_address.nil?
              lxc.customize 'network.ipv4.gateway', ip_gateway unless ip_gateway.nil?
            end
          end
        end
      end
    end
  end
end