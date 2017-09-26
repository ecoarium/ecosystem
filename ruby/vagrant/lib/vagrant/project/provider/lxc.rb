require "vagrant/project/provider/base"
require "vagrant/project/provider/lxc/config"

module Vagrant
  module Project
    module Provider
      class LXC < Base
        def initialize(vagrant_machine)
          @provider_symbol = :lxc
          super
        end

        def configuration
          @configuration = Vagrant::Project::Provider::LXCModule::Configuration.new if @configuration.nil?
          @configuration
        end

        def set_defaults(&block)
          super

          provider{|lxc|
            
          }
          
          provider(&block)
        end
      end
    end
  end
end


Vagrant::Project.provider_class = Vagrant::Project::Provider::LXC