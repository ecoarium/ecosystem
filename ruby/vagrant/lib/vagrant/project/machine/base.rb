require 'logging-helper'
require 'plugin/registrar'

module Vagrant
  module Project
    module Machine
      class Base
        include LoggingHelper::LogToTerminal
        extend ::Plugin::Registrar::Registrant

        registry(:machine).add_class_location(File.expand_path(File.dirname(__FILE__)))

        project_machine_class_path = "#{$WORKSPACE_SETTINGS[:paths][:project][:deploy][:vagrant][:lib]}/vagrant/project/machine"
        registry(:machine).add_class_location(project_machine_class_path) if File.exist?(project_machine_class_path)

        attr_reader :name, :vagrant_machine

        def initialize(name, vagrant_machine, provider_class)
          @name = name
          @vagrant_machine = vagrant_machine
          @provider_class = provider_class
          @dependencies = []
        end

        def configuration
          return @configuration unless @configuration.nil?
          @configuration = configuration_class.new
          @configuration.instance_variable_set(:@dependencies, [])

          @configuration.vagrant_machine vagrant_machine
          configuration_class.excluded_configurations << :@vagrant_machine

          @configuration.machine self
          configuration_class.excluded_configurations << :@machine

          @configuration.provisioner provisioner
          configuration_class.excluded_configurations << :@provisioner

          @configuration.provider provider.configuration
          configuration_class.excluded_configurations << :@provider
          @configuration
        end

        def provider
          return @provider unless @provider.nil?
          @provider = provider_class.new(vagrant_machine)
          @provider
        end

        def provisioner
          return @provisioner unless @provisioner.nil?
          @provisioner = provisioner_class.new(vagrant_machine)
          @provisioner
        end

        def configure_provider()
          provider.configure()
        end

        def configure_provisioner()
          configuration.configure(provisioner)
        end

        def configuration_class
          raise "this must be implemented in the machine class and return the full class name for the machine configuration class."
        end

        def provisioner_class
          raise "this must be implemented in the machine class and return the full class name for the provisioner class."
        end

        attr_reader :provider_class

      end
    end
  end
end
