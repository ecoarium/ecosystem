
module Smithers
  module ConfigurationItems
    class Builders
      class Bash
        include LoggingHelper::LogToTerminal
        include Attributes::Mixin::Method
        extend Plugin::Registrar::Registrant

        register :job_builders, :bash, self.inspect

        attr_reader :job, :configuration_block

        def initialize(job, parent, &block)
          @job = job
          @configuration_block = block
        end

        attr_method :script

        def configure
          instance_exec(&configuration_block)
          job.configuration['builders']['hudson.tasks.Shell'] = [] if job.configuration['builders']['hudson.tasks.Shell'].nil?

          job.configuration['builders']['hudson.tasks.Shell'].push(
            {
              'command' => script
            }
          )
        end

      end
    end
  end
end
