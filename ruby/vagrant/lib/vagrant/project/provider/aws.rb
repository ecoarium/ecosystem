require 'vagrant/project/provider/base'
require 'vagrant/project/provider/amazon/config'
require 'vagrant/project/provider/amazon/helper'

module Vagrant
  module Project
    module Provider
      class AWS < Base

        def initialize(vagrant_machine)
          @provider_symbol = :aws
          super
        end

        def configuration
          @configuration = Vagrant::Project::Provider::Amazon::Configuration.new if @configuration.nil?
          @configuration
        end

        def set_defaults(&block)
          super

          if vagrant_machine.vm.guest == :windows
            vagrant_machine.winrm.username = 'Administrator'
            vagrant_machine.winrm.password = Vagrant::Project::Provider::Amazon::Helper.windows_password(vagrant_machine)
          else
            provider_overrides{|override|
              override.ssh.username = 'ec2-user'
              override.ssh.private_key_path = Vagrant::Project::Provider::Amazon::Helper.ssh_key_file_path(vagrant_machine)
            }
          end

          provider(&block) if block_given?
          provider_overrides(&block) if block_given?
        end
      end
    end
  end
end


Vagrant::Project.provider_class = Vagrant::Project::Provider::AWS
