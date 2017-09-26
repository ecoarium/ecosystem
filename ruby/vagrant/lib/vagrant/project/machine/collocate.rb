require "deep_merge"
require 'plugin/registrar'
require "vagrant/project/machine/base"
require "vagrant/project/machine/config/base"
require "vagrant/project/mixins/configurable"
require 'logging-helper'

module Vagrant
  module Project
    module Machine
      class Collocate < Base
        class Configuration < Vagrant::Project::Machine::Config::Base
          include LoggingHelper::LogToTerminal

          def initialize
          end

          def configure_this(provisioner)
          end

          def method_missing(method_symbol, *args, &machine_config_block)
            machine_class = ::Plugin::Registrar::Registry.lookup(:machine, method_symbol)

            example = %/
underscored_machine_class_name :machine_name do
  config some_value
  another_confg something_else
end
/
            raise "You must supply a name, as a symbol, when declaring a machine:#{example}" unless args.size == 1 and args.first.is_a? Symbol

            inner_machine = machine_class.new(args.first, vagrant_machine, machine.provider_class)
            Vagrant::Project.project_environment.add_machine inner_machine

            inner_machine.instance_exec(machine){|parent_machine|
              @provisioner = parent_machine.provisioner
              @provider = parent_machine.provider
            }

            inner_machine.configuration.instance_eval(&machine_config_block)

            inner_machine.configure_provider()
            inner_machine.configure_provisioner()

            return inner_machine
          end

        end

        register :machine, :collocate, self.inspect

        def configuration_class
          Vagrant::Project::Machine::Collocate::Configuration
        end

        def provisioner_class
          require 'vagrant/project/provisioner/chef'
          Vagrant::Project::Provisioner::Chef
        end

      end
    end
  end
end
