require 'vagrant/project/provider/config/base'
require 'vagrant/project/provider/esxi/disk'
require 'vagrant/project/provider/esxi/network'

module Vagrant
  module Project
    module Provider
      class ESXI < Base
        class Configuration < Vagrant::Project::Provider::Config::Base
          
          attr_config :network, class: Vagrant::Project::Provider::ESXI::Config::Network
          attr_config :disk, class: Vagrant::Project::Provider::ESXI::Config::Disk, is_array: true
          
          attr_config :sync_vagrant_folder, :host, :datastore, :user, :password, :ssh_key_path
          attr_config :memory, :vcpus, :customizations

          def initialize
            @sync_vagrant_folder = true

            @customizations = {}
            
            @box = 'dummy'
            @box_url = File.expand_path("../../../../../boxes/esxi/dummy.box", File.dirname(__FILE__))
          end

          def configure_this(vagrant_machine, esxi)
            esxi.host         = host
            esxi.datastore    = datastore
            esxi.user         = user
            esxi.password     = password
            esxi.ssh_key_path = ssh_key_path

            unless memory.nil?
              esxi.memory = memory
            end

            unless vcpus.nil?
              esxi.vcpus = vcpus
            end

            customizations.each do |key, value|
              esxi.customize key,value
            end unless customizations.nil?

            unless sync_vagrant_folder
              synced_folders{
                host_path  $WORKSPACE_SETTINGS[:paths][:project][:deploy][:vagrant][:context][:home]
                guest_path '/vagrant'
                disabled = true
              }
            end
          end

          alias :original_network :network
          def network(*args, &block)
            original_network.set_ip_address(vagrant_machine)
            original_network(*args, &block)
          end
        end
      end
    end
  end
end