

module Smithers
  module ConfigurationItems
    class Triggers
      class Schedule
        include LoggingHelper::LogToTerminal
        include Attributes::Mixin::Method
        extend Plugin::Registrar::Registrant

        register :job_triggers, :schedule, self.inspect

        attr_reader :job, :configuration_block

        def initialize(job, parent, &block)
          @job = job
          @configuration_block = block
        end
        
        attr_method(
          {
            minute: 'H/60'
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

        def set_to_every_hour
          set_defaults
        end

        def set_to_every_day
          minute '0'
          hour '0'
          month '*'
          day_of_week '*'
          day_of_month '*'
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
            'hudson.triggers.TimerTrigger' => {
              'spec'                  => spec
            }
          })
        end

      end
    end
  end
end