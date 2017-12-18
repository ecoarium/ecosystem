require 'vagrant/project/provider/config/base'
require 'vagrant/project/provider/virtualbox/network'
require 'vagrant/project/provider/virtualbox/disk'

module Vagrant
  module Project
    module Provider
      module VirtualBox
        class Configuration < Vagrant::Project::Provider::Config::Base

          attr_config :network, class: Vagrant::Project::Provider::VirtualBox::Config::Network
          attr_config :disk, class: Vagrant::Project::Provider::VirtualBox::Config::Disk, is_array: true

          attr_config :memory, :cpus, :gui, :sync_vagrant_folder

          def initialize
            @gui = false
            @sync_vagrant_folder = true

            @box = 'dummy'
            @box_url = File.expand_path('../../../../../boxes/virtualbox/dummy.box', File.dirname(__FILE__))
          end

          def configure_this(vagrant_machine, vbox)
            unless memory.nil?
              vbox.customize ["modifyvm", :id, "--memory", memory]
            end

            unless cpus.nil?
              vbox.customize ["modifyvm", :id, "--cpus", cpus]
            end

            vbox.gui = gui

            vbox.linked_clone = true

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
