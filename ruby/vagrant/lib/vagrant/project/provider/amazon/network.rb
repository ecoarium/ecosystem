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

            attr_config :ip_address

            attr_config :address_type do

              if !address_types.any?{|type| address_type == type }
                {
                  is_valid: false,
                  failure_message: "
  The configuration item env_config must define these keys with values:
    * #{required_keys.join('\n  * ')}
  "
                }
              else
                {is_valid: true}
              end
            end

            def initialize
              @address_type = :private
            end

            def get_ip_address(vagrant_machine)
              return @ip_address unless @ip_address.nil?

              if address_type == :private
                @ip_address = Helper.ec2_private_ip(vagrant_machine)
              elsif address_type == :public
                @ip_address = Helper.ec2_public_ip(vagrant_machine)
              end

              @ip_address
            end

            def address_types
              [
                :private,
                :public,
                :elastic
              ]
            end
            
            def configure_this(vagrant_machine, aws)
              this_sets_the_ip_address_for_the_machine_report = get_ip_address(vagrant_machine)
              if address_type == :elastic
                aws.elastic_ip = get_ip_address(vagrant_machine)
              end
            end
          end
        end
      end
    end
  end
end