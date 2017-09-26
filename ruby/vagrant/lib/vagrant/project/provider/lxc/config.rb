require 'vagrant/project/provider/config/base'
require 'vagrant/project/provider/lxc/network'

module Vagrant
  module Project
    module Provider
      module LXCModule
        class Configuration < Vagrant::Project::Provider::Config::Base

          attr_config :network, class: Vagrant::Project::Provider::LXCModule::Config::Network

          attr_config :customizations, :backingstore, :backingstore_options, :container_name

          def initialize
            @box = 'dummy'
            @box_url = File.expand_path('../../../../../boxes/lxc/dummy.box', File.dirname(__FILE__))
          end

          def configure_this(vagrant_machine, lxc)
            customizations.each do |key, value|
              if (key != 'network.ipv4' or ip_address.nil?) and (key != 'network.ipv4.gateway' or ip_gateway.nil?)
                lxc.customize key,value
              end
            end unless customizations.nil?

            lxc.backingstore = backingstore unless backingstore.nil?

            backingstore_options.each do |key, value|
              lxc.backingstore_option key, value
            end unless backingstore_options.nil?

            lxc.container_name = container_name unless container_name.nil?
          end
        end
      end
    end
  end
end
