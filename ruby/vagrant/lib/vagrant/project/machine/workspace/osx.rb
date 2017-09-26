require "deep_merge"
require "vagrant/project/machine/base"
require "vagrant/project/machine/config/base"
require "vagrant/project/mixins/configurable"
require 'logging-helper'

module Vagrant
  module Project
    module Machine
      module Workspace
        class OSX < Base
          class Configuration < Vagrant::Project::Machine::Config::Base
            include LoggingHelper::LogToTerminal

            def configure_this(provisioner)
              artifact_name = $WORKSPACE_SETTINGS[:vagrant][:boxes][:osx][:name]
              artifact_version = $WORKSPACE_SETTINGS[:vagrant][:boxes][:osx][:version]
              provider.box_from_nexus(artifact_name, artifact_version)

              provider.os_name :darwin
              provider.os_version artifact_name.gsub(/osx|-/,'').upcase
            end

          end

          register :machine, :osx_workspace, self.inspect

          def configuration_class
            Vagrant::Project::Machine::Workspace::OSX::Configuration
          end

          def provisioner_class
            require 'vagrant/project/provisioner/none'
            Vagrant::Project::Provisioner::None
          end

        end
      end
    end
  end
end