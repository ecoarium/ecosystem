require 'vagrant/project/provider/config/base'
require 'vagrant/project/provider/vsphere/disk'
require 'vagrant/project/provider/vsphere/network'

module Vagrant
  module Project
    module Provider
      class VSphere < Base
        class Configuration < Vagrant::Project::Provider::Config::Base
          
          attr_config :network, class: Vagrant::Project::Provider::VSphere::Config::Network
          
          attr_config :sync_vagrant_folder, :host, :compute_resource_name
          attr_config :user, :password, :resource_pool_name
          attr_config :memory, :vcpus, :template_name, :template_path
          attr_config :data_center_name, :data_store_name, :customization_spec_name
          #attr_config :disk, class: Vagrant::Project::Provider::VSphere::Config::Disk, is_array: true

          def initialize
            @sync_vagrant_folder = true
            
            @box = 'dummy'
            @box_url = File.expand_path("../../../../../boxes/vsphere/dummy.box", File.dirname(__FILE__))
          end

          def configure_this(vagrant_machine, vsphere)
            vsphere.host                    = host
            vsphere.user                    = user
            vsphere.password                = password
            vsphere.compute_resource_name   = compute_resource_name
            vsphere.resource_pool_name      = resource_pool_name
            vsphere.template_name           = "#{template_path}/#{template_name}"
            vsphere.insecure                = true
            vsphere.data_center_name        = data_center_name
            vsphere.data_store_name         = data_store_name
            vsphere.customization_spec_name = customization_spec_name

            unless memory.nil?
              vsphere.memory_mb = memory
            end

            unless vcpus.nil?
              vsphere.cpu_count = vcpus
            end

            unless sync_vagrant_folder
              synced_folders{
                host_path  $WORKSPACE_SETTINGS[:paths][:project][:deploy][:vagrant][:context][:home]
                guest_path '/vagrant'
                disabled = true
              }
            end
          end
        end
      end
    end
  end
end