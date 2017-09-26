require 'vagrant/project/provider/base'
require 'vagrant/project/provider/esxi/config'

module Vagrant
  module Project
    module Provider
    	class ESXI < Base

        def initialize(vagrant_machine)
          @provider_symbol = :esxi
          super
        end

        def configuration
        	@configuration = Vagrant::Project::Provider::ESXI::Configuration.new if @configuration.nil?
        	@configuration
        end

        def set_defaults(&block)
          super

          provider{|esxi|
            time_bomb("02/12/2017 02:00 PM", "esxi.name needs to be set much like aws tags")
          }

          provider(&block)  if block_given?
        end
      end
    end
  end
end

Vagrant::Project.provider_class = Vagrant::Project::Provider::ESXI
