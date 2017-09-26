require "deep_merge"
require "vagrant/project/machine/base"
require "vagrant/project/machine/config/base"
require "vagrant/project/mixins/configurable"
require 'logging-helper'

module Vagrant
  module Project
    module Machine
      class Windows < Base
        class Configuration < Vagrant::Project::Machine::Config::Base
          include LoggingHelper::LogToTerminal

          def initialize

          end

          def configure_this(provisioner)
            artifact_name = $WORKSPACE_SETTINGS[:vagrant][:boxes][:windows][:name]
            artifact_version = $WORKSPACE_SETTINGS[:vagrant][:boxes][:windows][:version]
            provider.box_from_nexus(artifact_name, artifact_version)

            provider.os_name 'windows'
            provider.os_version artifact_name.gsub(/windows|-/,'').upcase

            vagrant_machine.vm.communicator = 'winrm'
            vagrant_machine.vm.guest = :windows
            vagrant_machine.vm.network :forwarded_port, guest: 3389, host: 3389, id: 'rdp', auto_correct: true
            vagrant_machine.winrm.password = 'vagrant'
          end

        end

        register :machine, :windows_workspace, self.inspect

        def configuration_class
          Vagrant::Project::Machine::Windows::Configuration
        end

        def provisioner_class
          require 'vagrant/project/provisioner/none'
          Vagrant::Project::Provisioner::None
        end

      end
    end
  end
end
