require 'vagrant/project/mixins/data_bags'
require 'chef/data_bags/reader'
require 'plugin/registrar'
require 'httparty'
require 'open-uri'
require 'json'

module Vagrant
  module Project
    module Environment
      class Base
        include Vagrant::Project::Mixins::DataBags
        extend ::Plugin::Registrar::Registrant

        registry(:environment).add_class_location(File.expand_path(File.dirname(__FILE__)))

        project_environment_class_path = "#{$WORKSPACE_SETTINGS[:paths][:project][:deploy][:vagrant][:lib]}/vagrant/project/environment"
        registry(:environment).add_class_location(project_environment_class_path) if File.exist?(project_environment_class_path)

        attr_accessor :vagrant_env, :root_dir, :vagrant_file_path
        attr_accessor :provider_name, :provider_class
        attr_accessor :box, :box_url
        attr_accessor :provisioner_class

        attr_reader :machines

        def add_machine(machine)
          @machines = {} if @machines.nil?
          @machines[machine.name] = machine
        end

        [
          :configure_provisioner,
          :configure_provider
        ].each do |meth|
          define_method(meth) { raise "not implemented and required!" }
        end

        def validate!
          machines.each{|machine|
            machine.validate!
          }
          validate_variables
        end

        def validate_variables
          instance_variables.each{|var_name|
            var = instance_variable_get(var_name.to_s)
            if var.respond_to?(:validate!)
              var.validate!
            end
          }
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
          raise "You must supply a configuration block when declaring a machine:#{example}" unless block_given?

          vagrant_env.vm.define(args.first){|vagrant_machine|
            vagrant_machine.instance_eval{
              def root_dir
                @root_dir
              end
              def vagrant_file_path
                @vagrant_file_path
              end
              def machine_type
                @machine_type
              end
              def name
                @name
              end
              def provider_name
              	@provider_name
              end
              def data_dir
              	@data_dir
              end
              def id_file
              	@id_file
              end
            }
            data_dir = File.expand_path(".vagrant/machines/#{args.first}/#{provider_name}", File.dirname(vagrant_file_path))
            vagrant_machine.instance_variable_set(:@root_dir, root_dir)
            vagrant_machine.instance_variable_set(:@vagrant_file_path, vagrant_file_path)
            vagrant_machine.instance_variable_set(:@machine_type, method_symbol)
            vagrant_machine.instance_variable_set(:@name, args.first)
            vagrant_machine.instance_variable_set(:@provider_name, provider_name)
            vagrant_machine.instance_variable_set(:@data_dir, data_dir)
            vagrant_machine.instance_variable_set(:@id_file, "#{data_dir}/id")

            machine = machine_class.new(args.first, vagrant_machine, provider_class)
            add_machine machine

            machine.configuration.instance_eval(&machine_config_block)

            configure_provider(machine){
              machine.configure_provider()
            }

            configure_provisioner(machine){
              machine.configure_provisioner()
            }
          }
        end

      end
    end
  end
end
