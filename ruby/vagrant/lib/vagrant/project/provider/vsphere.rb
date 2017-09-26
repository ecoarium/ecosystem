require 'vagrant/project/provider/base'
require 'vagrant/project/provider/vsphere/config'

module Vagrant
  module Project
    module Provider
    	class VSphere < Base

        def initialize(vagrant_machine)
          @provider_symbol = :vsphere
          super
        end

        def configuration
        	@configuration = Vagrant::Project::Provider::VSphere::Configuration.new if @configuration.nil?
        	@configuration
        end

        def set_defaults(&block)
          super

          provider{|vsphere|
            vsphere.name = vagrant_machine.name
            time_bomb("09/22/2016 02:00 PM", "vsphere.name needs to be set much like aws tags")
          }

          provider(&block)  if block_given?
        end
      end
    end
  end
end

Vagrant::Project.provider_class = Vagrant::Project::Provider::VSphere
