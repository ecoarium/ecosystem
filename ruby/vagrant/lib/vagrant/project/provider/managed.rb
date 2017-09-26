require "vagrant/project/provider/base"
require 'vagrant/project/provider/managed/config'

module Vagrant
  module Project
    module Provider
    	class Managed < Base

        def initialize(vagrant_machine)
          @provider_symbol = :managed
          super
        end

        def configuration
          @configuration = Vagrant::Project::Provider::Managed::Configuration.new if @configuration.nil?
          @configuration
        end

        def set_defaults(&block)
          super

          provider{|vbox|
            
          }

          provider(&block)  if block_given?
        end
      end
    end
  end
end


Vagrant::Project.provider_class = Vagrant::Project::Provider::Managed
