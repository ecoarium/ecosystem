
module Smithers
  module ConfigurationItems
    class Properties
      class Parameters
        class StringParameter
          include LoggingHelper::LogToTerminal
          include Attributes::Mixin::Method
          extend Plugin::Registrar::Registrant

          register :job_parameters, :string_parameter, self.inspect

          attr_reader :job, :configuration_block

          def initialize(job, parent, &block)
            @job = job
            @configuration_block = block
          end

          attr_method :name, :description, :default_value

          def configure
            instance_exec(&configuration_block)
            job.configuration['properties']['hudson.model.ParametersDefinitionProperty']['parameterDefinitions']['hudson.model.StringParameterDefinition'] = [] if job.configuration['properties']['hudson.model.ParametersDefinitionProperty']['parameterDefinitions']['hudson.model.StringParameterDefinition'].nil?

            job.configuration['properties']['hudson.model.ParametersDefinitionProperty']['parameterDefinitions']['hudson.model.StringParameterDefinition'].push(
              {
                'name'         => name,
                'description'  => description,
                'defaultValue' => default_value
              }
            )
          end

        end
      end
    end
  end
end
