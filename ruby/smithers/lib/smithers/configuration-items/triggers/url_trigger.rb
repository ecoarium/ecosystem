
module Smithers
  module ConfigurationItems
    class Triggers
      class UrlTrigger
        include LoggingHelper::LogToTerminal
        include Attributes::Mixin::Method
        extend Plugin::Registrar::Registrant

        register :job_triggers, :url_trigger, self.inspect

        attr_reader :job, :configuration_block

        def initialize(job, parent, &block)
          @job = job
          @configuration_block = block
        end

        attr_method :url

        attr_method(
          {
            minute: '*'
          },
          {
            hour: '*'
          },
          {
            month: '*'
          },
          {
            day_of_week: '*'
          },
          {
            day_of_month: '*'
          }
        )

        def set_to_every_minute
          set_defaults
        end

        def configure
          instance_exec(&configuration_block)

          spec = [
            minute,
            hour,
            day_of_month,
            month,
            day_of_week
          ].join(' ')

          job.configuration['triggers'].deep_merge!({
            "org.jenkinsci.plugins.urltrigger.URLTrigger" => {
              "spec"             => spec,
              "entries"          => {
                "org.jenkinsci.plugins.urltrigger.URLTriggerEntry" => {
                  "url"                       => url,
                  "proxyActivated"            => "false",
                  "checkStatus"               => "false",
                  "statusCode"                => "200",
                  "timeout"                   => "300",
                  "checkETag"                 => "false",
                  "checkLastModificationDate" => "true",
                  "inspectingContent"         => "true",
                  "contentTypes"              => {
                    "org.jenkinsci.plugins.urltrigger.content.SimpleContentType" => {}
                  }
                }
              },
              "labelRestriction" => "false"
            }
          })
        end

      end
    end
  end
end
