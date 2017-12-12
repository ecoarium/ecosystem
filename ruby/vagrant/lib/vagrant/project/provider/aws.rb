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
            vagrant_machine.vm.communicator = 'winrm'
            vagrant_machine.winrm.username = 'Administrator'
            vagrant_machine.winrm.password = :aws
            vagrant_machine.vm.allowed_synced_folder_types = [:winrm]


            provider{|aws|
              aws.user_data = <<-USERDATA
  <powershell>
    Enable-PSRemoting -Force
    netsh advfirewall firewall add rule name="WinRM HTTP" dir=in localport=5985 protocol=TCP action=allow
  </powershell>
USERDATA
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
