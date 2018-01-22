require "vagrant/project/mixins/configurable"
require 'vagrant/project/provider/amazon/helper'

module Vagrant
  module Project
    module Provider
      module Amazon
        module Config
          class Network
            include Vagrant::Project::Mixins::Configurable
            include LoggingHelper::LogToTerminal

            attr_config :ip_address, :elastic_ip

            def initialize

            end

            def configure_this(vagrant_machine, aws)
              if elastic_ip.nil?
                @ip_address = Helper.ec2_public_ip(vagrant_machine)
              else
                aws.elastic_ip = elastic_ip
                @ip_address = elastic_ip
              end
            end
          end
        end
      end
    end
  end
end
