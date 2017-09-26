
module Smithers
  module ConfigurationItems
    class Publishers
      class Mailer
        include LoggingHelper::LogToTerminal
        include Attributes::Mixin::Method
        extend Plugin::Registrar::Registrant

        register :job_publishers, :mailer, self.inspect

        attr_reader :job, :configuration_block

        def initialize(job, parent, &block)
          @job = job
          @configuration_block = block
        end
        
        attr_method :recipients
        
        def configure
          instance_exec(&configuration_block)

          job.configuration['publishers'].deep_merge!({
            'hudson.tasks.Mailer' => {
              'recipients'                   => recipients,
              'dontNotifyEveryUnstableBuild' => false,
              'sendToIndividuals'            => true
            }
          })
        end

      end
    end
  end
end