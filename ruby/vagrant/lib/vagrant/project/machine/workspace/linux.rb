require "deep_merge"
require "vagrant/project/machine/base"
require "vagrant/project/machine/config/base"
require "vagrant/project/mixins/configurable"
require 'logging-helper'

module Vagrant
  module Project
    module Machine
      module Workspace
        class Linux < Base
          class Configuration < Vagrant::Project::Machine::Config::Base
            include LoggingHelper::LogToTerminal

            def configure_this(provisioner)
              artifact_name = $WORKSPACE_SETTINGS[:vagrant][:boxes][:centos][:name]
              artifact_version = $WORKSPACE_SETTINGS[:vagrant][:boxes][:centos][:version]
              provider.box_from_nexus(artifact_name, artifact_version)
            end

          end

          register :machine, :linux_workspace, self.inspect

          def configuration_class
            Vagrant::Project::Machine::Workspace::Linux::Configuration
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