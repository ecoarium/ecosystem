
module Smithers
  module ConfigurationItems
    class Publishers
      class Crap4j
        include LoggingHelper::LogToTerminal
        include Attributes::Mixin::Method
        extend Plugin::Registrar::Registrant

        register :job_publishers, :crap4j, self.inspect

        attr_reader :job, :configuration_block

        def initialize(job, parent, &block)
          @job = job
          @configuration_block = block

          set_defaults
        end
        
        attr_method({
          report_pattern: 'production/.build/reports/crap4j/report.xml'
        })
        
        def configure
          instance_exec(&configuration_block)

          job.configuration['publishers'].deep_merge!({
            "hudson.plugins.crap4j.Crap4JPublisher" => {
              "reportPattern"   => report_pattern,
              "healthThreshold" => {}
            }
          })
        end

      end
    end
  end
end