
module Smithers
  module ConfigurationItems
    class Publishers
      class Postbuild
        include LoggingHelper::LogToTerminal
        include Attributes::Mixin::Method
        extend Plugin::Registrar::Registrant

        register :job_publishers, :postbuild, self.inspect

        attr_reader :job, :configuration_block

        def initialize(job, parent, &block)
          @job = job
          @configuration_block = block

          set_defaults
        end

        attr_method :script

        attr_method(
          {
            log_text: {}
          },
          {
            operator: 'AND'
          },
          {
            escalate_status: 'false'
          },
          {
            run_if_job_successful: 'true'
          }
        )

        def configure
          instance_exec(&configuration_block)

          job.configuration['publishers'].deep_merge!({
            "hudson.plugins.postbuildtask.PostbuildTask" => {
              "tasks" => {
                "hudson.plugins.postbuildtask.TaskProperties" => {
                  "logTexts" => {
                    "hudson.plugins.postbuildtask.LogProperties" => {
                      "logText"  => log_text,
                      "operator" => operator
                    }
                  },
                  "EscalateStatus"     => escalate_status,
                  "RunIfJobSuccessful" => run_if_job_successful,
                  "script"             => script
                }
              }
            }
          })
        end
      end
    end
  end
end
