require 'vagrant/conventions/provider/virtualbox'
require 'vagrant/project/provider/base'
require 'vagrant/project/provider/virtualbox/config'

module Vagrant
  module Project
    module Provider
    	class VBox < Base

        def initialize(vagrant_machine)
          @provider_symbol = :virtualbox
          super
        end

        def configuration
        	@configuration = Vagrant::Project::Provider::VirtualBox::Configuration.new if @configuration.nil?
        	@configuration
        end

        def set_defaults(&block)
          super
          provider{|vbox|
            vbox.name = Vagrant::Conventions::Provider::VirtualBox.format_machine_name(vagrant_machine.name)
          }

          provider(&block)  if block_given?
        end
      end
    end
  end
end

Vagrant::Project.provider_class = Vagrant::Project::Provider::VBox
