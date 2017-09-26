
module Smithers
  module ConfigurationItems
    class Properties
      class Parameters
        class Extensible
          include LoggingHelper::LogToTerminal
          include Attributes::Mixin::Method
          extend Plugin::Registrar::Registrant

          register :job_parameters, :extensible, self.inspect

          attr_reader :job, :configuration_block

          def initialize(job, parent, &block)
            @job = job
            @configuration_block = block
          end
          
          attr_method :name, :description, :script
          
          def configure
            instance_exec(&configuration_block)
            job.configuration['properties']['hudson.model.ParametersDefinitionProperty']['parameterDefinitions']['jp.ikedam.jenkins.plugins.extensible__choice__parameter.ExtensibleChoiceParameterDefinition'] = [] if job.configuration['properties']['hudson.model.ParametersDefinitionProperty']['parameterDefinitions']['jp.ikedam.jenkins.plugins.extensible__choice__parameter.ExtensibleChoiceParameterDefinition'].nil?

            job.configuration['properties']['hudson.model.ParametersDefinitionProperty']['parameterDefinitions']['jp.ikedam.jenkins.plugins.extensible__choice__parameter.ExtensibleChoiceParameterDefinition'].push(
              {
                '@plugin'      => 'extensible-choice-parameter@1.3.2',
                'name'         => name,
                'description'  => description,
                'editable'     => 'false',
                'choiceListProvider' => {
                  '@class'        => 'jp.ikedam.jenkins.plugins.extensible_choice_parameter.SystemGroovyChoiceListProvider',
                  'scriptText'    => script,
                  'usePredefinedVariables' => 'false'
                }
              }
            )
          end

        end
      end
    end
  end
end
