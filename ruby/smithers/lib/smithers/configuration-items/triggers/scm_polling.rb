

module Smithers
  module ConfigurationItems
    class Triggers
      class ScmPolling
        include LoggingHelper::LogToTerminal
        include Attributes::Mixin::Method
        extend Plugin::Registrar::Registrant

        register :job_triggers, :scm_polling, self.inspect

        attr_reader :job, :configuration_block

        def initialize(job, parent, &block)
          @job = job
          @configuration_block = block
        end
        
        attr_method(
          {
            minute: '*'
          },
          {
            hour: '*'
          },
          {
            month: '*'
          },
          {
            day_of_week: '*'
          },
          {
            day_of_month: '*'
          }
        )

        def set_to_every_minute
          set_defaults
        end
        
        def configure
          instance_exec(&configuration_block)

          spec = [
            minute,
            hour,
            day_of_month,
            month,
            day_of_week
          ].join(' ')

          job.configuration['triggers'].deep_merge!({
            'hudson.triggers.SCMTrigger' => {
              'spec'                  => spec,
              'ignorePostCommitHooks' => false
            }
          })
        end

      end
    end
  end
end