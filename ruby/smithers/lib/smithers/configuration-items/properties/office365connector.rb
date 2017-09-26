module Smithers
  module ConfigurationItems
    class Properties
      class Office356Connector
        include LoggingHelper::LogToTerminal
        include Attributes::Mixin::Method
        extend Plugin::Registrar::Registrant

        register :job_properties, :office_365_connector, self.inspect

        attr_reader :job, :configuration_block

        def initialize(job, parent, &block)
          @job = job
          @configuration_block = block

          set_defaults
        end

        attr_method :url
        attr_method(
          {
            startNotification: 'false'
          },
          {
            notifySuccess: 'true'
          },
          {
            notifyAborted: 'false'
          },
          {
            notifyNotBuilt: 'false'
          },
          {
            notifyUnstable: 'false'
          },
          {
            notifyFailure: 'false'
          },
          {
            notifyBackToNormal: 'true'
          },
          {
            notifyRepeatedFailure: 'false'
          },
          {
            timeout: 30000
          }
        )

        def configure
          instance_exec(&configuration_block)
          job.configuration['properties'].deep_merge!({
            "jenkins.plugins.office365connector.WebhookJobProperty"  => {
               "webhooks" => {
                 "jenkins.plugins.office365connector.Webhook" => {
                   "url"                   => url,
                   "startNotification"     => startNotification,
                   "notifySuccess"         => notifySuccess,
                   "notifyAborted"         => notifyAborted,
                   "notifyNotBuilt"        => notifyNotBuilt,
                   "notifyUnstable"        => notifyUnstable,
                   "notifyFailure"         => notifyFailure,
                   "notifyBackToNormal"    => notifyBackToNormal,
                   "notifyRepeatedFailure" => notifyRepeatedFailure,
                   "timeout"               => timeout
                 }
               }
             }
          })
        end
      end
    end
  end
end
