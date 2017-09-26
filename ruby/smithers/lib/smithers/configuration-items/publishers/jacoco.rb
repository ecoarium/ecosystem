
module Smithers
  module ConfigurationItems
    class Publishers
      class Jacoco
        include LoggingHelper::LogToTerminal
        include Attributes::Mixin::Method
        extend Plugin::Registrar::Registrant

        register :job_publishers, :jacoco, self.inspect

        attr_reader :job, :configuration_block

        def initialize(job, parent, &block)
          @job = job
          @configuration_block = block

          set_defaults
        end

        attr_method(
          {
            exec_pattern: 'production/**/**.exec'
          },
          {
            class_pattern: 'production/**/classes'
          },
          {
            source_pattern: 'production/**/src/main/java'
          }
        )
        
        def configure
          instance_exec(&configuration_block)

          job.configuration['publishers'].deep_merge!({
            "hudson.plugins.jacoco.JacocoPublisher" => {
              "execPattern"                => exec_pattern,
              "classPattern"               => class_pattern,
              "sourcePattern"              => source_pattern,
              "inclusionPattern"           => {},
              "exclusionPattern"           => {},
              "minimumInstructionCoverage" => "0",
              "minimumBranchCoverage"      => "0",
              "minimumComplexityCoverage"  => "0",
              "minimumLineCoverage"        => "0",
              "minimumMethodCoverage"      => "0",
              "minimumClassCoverage"       => "0",
              "maximumInstructionCoverage" => "0",
              "maximumBranchCoverage"      => "0",
              "maximumComplexityCoverage"  => "0",
              "maximumLineCoverage"        => "0",
              "maximumMethodCoverage"      => "0",
              "maximumClassCoverage"       => "0",
              "changeBuildStatus"          => "false"
            }
          })
        end

      end
    end
  end
end