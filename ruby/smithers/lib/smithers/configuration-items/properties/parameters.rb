
module Smithers
  module ConfigurationItems
    class Properties
      class Parameters
        include LoggingHelper::LogToTerminal
        include Attributes::Mixin::Method
        include Plugin::MethodMissingIntercept::Flexible
        extend Plugin::Registrar::Registrant

        register :job_properties, :parameters, self.inspect

        attr_reader :job, :parent, :configuration_block

        def initialize(job, parent, &block)
          @job = job
          @parent = parent
          @configuration_block = block
          additional_arguments.push @job
          additional_arguments.push self
        end
        
        def configure
          job.configuration['properties']['hudson.model.ParametersDefinitionProperty'] = {
            'parameterDefinitions' => {}
          } if job.configuration['properties']['hudson.model.ParametersDefinitionProperty'].nil?

          instance_exec(&configuration_block)
        end

        def registry_name
          :job_parameters
        end

        def plugin_action_method_name
          :configure
        end

        def signature
          [Proc]
        end

      end
    end
  end
end