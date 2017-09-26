
module Smithers
  module ConfigurationItems
    class Publishers
      class Performance
        include LoggingHelper::LogToTerminal
        include Attributes::Mixin::Method
        extend Plugin::Registrar::Registrant

        register :job_publishers, :performance, self.inspect

        attr_reader :job, :configuration_block

        def initialize(job, parent, &block)
          @job = job
          @configuration_block = block
        end

        attr_method :report_directory_path

        def configure
          instance_exec(&configuration_block)

          job.configuration['publishers'].deep_merge!({
            "hudson.plugins.performance.PerformancePublisher" => {
              "errorFailedThreshold"               => "0",
              "errorUnstableThreshold"             => "0",
              "errorUnstableResponseTimeThreshold" => {},
              "relativeFailedThresholdPositive"    => "0.0",
              "relativeFailedThresholdNegative"    => "0.0",
              "relativeUnstableThresholdPositive"  => "0.0",
              "relativeUnstableThresholdNegative"  => "0.0",
              "nthBuildNumber"                     => "0",
              "modeRelativeThresholds"             => "false",
              "configType"                         => "ART",
              "modeOfThreshold"                    => "false",
              "failBuildIfNoResultFile"            => "false",
              "compareBuildPrevious"               => "false",
              "xml"                                => {},
              "modePerformancePerTestCase"         => "true",
              "parsers"                            => {
                "hudson.plugins.performance.JMeterParser" => {
                  "glob" => report_directory_path
                }
              },
              "modeThroughput"                     => "true",
              "modeEvaluation"                     => "false",
              "ignoreFailedBuilds"                 => "false",
              "ignoreUnstableBuilds"               => "false",
              "persistConstraintLog"               => "false"
            }
          })
        end

      end
    end
  end
end
