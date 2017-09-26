
module Smithers
  module ConfigurationItems
    class Publishers
      class JUnit
        include LoggingHelper::LogToTerminal
        include Attributes::Mixin::Method
        extend Plugin::Registrar::Registrant

        register :job_publishers, :junit, self.inspect

        attr_reader :job, :configuration_block

        def initialize(job, parent, &block)
          @job = job
          @configuration_block = block

          set_defaults
        end
        
        attr_method({
          result_glob_path: 'production/**/.build/test-results/*.xml'
        })
        
        def configure
          instance_exec(&configuration_block)

          job.configuration['publishers'].deep_merge!({
            'hudson.tasks.junit.JUnitResultArchiver' => {
              'testResults'       => result_glob_path,
              'keepLongStdio'     => true,
              'healthScaleFactor' => '1.0'
            }
          })
        end

      end
    end
  end
end