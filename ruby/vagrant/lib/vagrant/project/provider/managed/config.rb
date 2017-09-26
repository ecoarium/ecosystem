require 'vagrant/project/provider/config/base'
require 'vagrant/project/provider/virtualbox/network'

module Vagrant
  module Project
    module Provider
    	class Managed < Base
				class Configuration < Vagrant::Project::Provider::Config::Base

					#attr_config :network, class: Vagrant::Project::Provider::Managed::Config::Network

          attr_config :sync_vagrant_folder, :host

          def initialize
            @gui = false
            @sync_vagrant_folder = true

            @box = 'dummy'
            @box_url = File.expand_path("../../../../../boxes/managed/dummy.box", File.dirname(__FILE__))
          end

				  def configure_this(vagrant_machine, managed)
            managed.server = host

            unless sync_vagrant_folder
              synced_folders{
                host_path  $WORKSPACE_SETTINGS[:paths][:vagrant_context_path]
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
