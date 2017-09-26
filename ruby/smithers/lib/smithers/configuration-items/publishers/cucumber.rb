
module Smithers
  module ConfigurationItems
    class Publishers
      class Cucumber
        include LoggingHelper::LogToTerminal
        include Attributes::Mixin::Method
        extend Plugin::Registrar::Registrant

        register :job_publishers, :cucumber, self.inspect

        attr_reader :job, :configuration_block

        def initialize(job, parent, &block)
          @job = job
          @configuration_block = block

          set_defaults
        end
        
        attr_method :file_include_pattern
        attr_method(
          {
            json_report_directory: 'tests/acceptance/.reports'
          }
        )
        
        def configure
          instance_exec(&configuration_block)

          job.configuration['publishers'].deep_merge!({
            "net.masterthought.jenkins.CucumberReportPublisher" => {
              "jsonReportDirectory" => json_report_directory,
              "jenkinsBasePath"     => {},
              "fileIncludePattern"  => file_include_pattern,
              "fileExcludePattern"  => {},
              "skippedFails"        => "false",
              "pendingFails"        => "false",
              "undefinedFails"      => "false",
              "missingFails"        => "false",
              "ignoreFailedTests"   => "false",
              "parallelTesting"     => "true"
            }
          })
        end

      end
    end
  end
end