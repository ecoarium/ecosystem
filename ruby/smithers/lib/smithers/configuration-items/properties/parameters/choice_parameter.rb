
module Smithers
  module ConfigurationItems
    class Properties
      class Parameters
        class ChoiceParameter
          include LoggingHelper::LogToTerminal
          include Attributes::Mixin::Method
          extend Plugin::Registrar::Registrant

          register :job_parameters, :choice_parameter, self.inspect

          attr_reader :job, :configuration_block

          def initialize(job, parent, &block)
            @job = job
            @configuration_block = block
          end

          attr_method :name, :description, :choices

          def configure
            instance_exec(&configuration_block)
            job.configuration['properties']['hudson.model.ParametersDefinitionProperty']['parameterDefinitions']['hudson.model.ChoiceParameterDefinition'] = [] if job.configuration['properties']['hudson.model.ParametersDefinitionProperty']['parameterDefinitions']['hudson.model.ChoiceParameterDefinition'].nil?
            items = []
            choices.split(',').each do |item|
              items.push item
            end
            job.configuration['properties']['hudson.model.ParametersDefinitionProperty']['parameterDefinitions']['hudson.model.ChoiceParameterDefinition'].push(
              {
                'name'         => name,
                'description'  => description,
                "choices"     => {
                  "@class" => "java.util.Arrays$ArrayList",
                    "a"      => {
                    "@class" => "string-array",
                    "string" => items
                  }
                }
              }
            )
          end

        end
      end
    end
  end
end
