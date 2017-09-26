
module Smithers
  module ConfigurationItems
    class Publishers
      class ParameterizedTrigger
        include LoggingHelper::LogToTerminal
        include Attributes::Mixin::Method
        extend Plugin::Registrar::Registrant

        register :job_publishers, :parameterized_trigger, self.inspect

        attr_reader :job, :configuration_block

        def initialize(job, parent, &block)
          @job = job
          @configuration_block = block
          set_defaults
        end

        attr_method(
          {
            properties_file_path: Smithers::Environment.down_stream_job_properties_file_path
          },
          {
            job_short_names: []
          }
        )

        attr_method :failTriggerOnMissing, :triggerWithNoParameters

        def configure
          instance_exec(&configuration_block)

          projects = job_short_names.collect{|job_short_name|
            [
              Smithers::Environment.project_name,
              Smithers::Environment.branch_name,
              job_short_name
            ].join(Smithers::Environment.delimiter)
          }.join(',')

          job.configuration['publishers'].deep_merge!({
            "hudson.plugins.parameterizedtrigger.BuildTrigger" => {
              "configs" => {
                "hudson.plugins.parameterizedtrigger.BuildTriggerConfig" => {
                  "configs"                 => {
                    "hudson.plugins.parameterizedtrigger.FileBuildParameters" => {
                      "propertiesFile"       => properties_file_path,
                      "failTriggerOnMissing" => failTriggerOnMissing || "true",
                      "useMatrixChild"       => "false",
                      "onlyExactRuns"        => "false"
                    }
                  },
                  "projects"                => projects,
                  "condition"               => "SUCCESS",
                  "triggerWithNoParameters" => triggerWithNoParameters || "false"
                }
              }
            }
          })
        end

      end
    end
  end
end
