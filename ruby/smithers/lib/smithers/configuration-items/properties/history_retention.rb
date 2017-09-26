
module Smithers
  module ConfigurationItems
    class Properties
      class HistoryRetention
        include LoggingHelper::LogToTerminal
        include Attributes::Mixin::Method
        extend Plugin::Registrar::Registrant

        register :job_properties, :history_retention, self.inspect

        attr_reader :job, :configuration_block

        def initialize(job, parent, &block)
          @job = job
          @configuration_block = block
        end
        
        attr_method(
          {
            days_to_keep: 30
          },
          {
            number_to_keep: 120
          }
        )

        def set_to_default_30_days_or_120_builds
          set_defaults
        end
        
        def configure
          instance_exec(&configuration_block)

          job.configuration['properties'].deep_merge!({
            'jenkins.model.BuildDiscarderProperty' => {
              'strategy' => {
                '@class'             => 'hudson.tasks.LogRotator',
                'daysToKeep'         => days_to_keep,
                'numToKeep'          => number_to_keep,
                'artifactDaysToKeep' => days_to_keep,
                'artifactNumToKeep'  => number_to_keep
              }
            }
          })
        end

      end
    end
  end
end
