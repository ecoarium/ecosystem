
module Smithers
  module ConfigurationItems
    class Publishers
      class ExtMailer
        include LoggingHelper::LogToTerminal
        include Attributes::Mixin::Method
        extend Plugin::Registrar::Registrant

        register :job_publishers, :ext_mailer, self.inspect

        attr_reader :job, :configuration_block


        def initialize(job, parent, &block)
          @job = job
          @configuration_block = block
        end

        attr_method :recipients_list
        attr_method :subject
        attr_method :content
        attr_method :fail_trigger_recipients_list
        attr_method :always_trigger_recipients_list
         attr_method(
          {
            fail_trigger_notify_developer: "true"
          },
          {
            always_trigger: "true"
          }
        )

        def configure
          instance_exec(&configuration_block)

          triggers = {}
          fail_trigger_list_item = {}
          if fail_trigger_recipients_list == ""
            fail_trigger_list_item["recipientList"] = {}
          else
            fail_trigger_list_item["recipientList"] = fail_trigger_recipients_list
          end
          triggers["hudson.plugins.emailext.plugins.trigger.FailureTrigger"] = {
                    "email" => {
                        "recipientList"      =>fail_trigger_list_item["recipientList"],
                        "subject"            => "$PROJECT_DEFAULT_SUBJECT",
                        "body"               => "$PROJECT_DEFAULT_CONTENT",
                        "recipientProviders" => {},
                        "attachmentsPattern" => {},
                        "attachBuildLog"     => "false",
                        "compressBuildLog"   => "false",
                        "replyTo"            => "$PROJECT_DEFAULT_REPLYTO",
                        "contentType"        => "project"
                    }
                  }

          if fail_trigger_notify_developer == 'true'
             triggers["hudson.plugins.emailext.plugins.trigger.FailureTrigger"]["email"]["recipientProviders"] = {
                            "hudson.plugins.emailext.plugins.recipients.DevelopersRecipientProvider" => {}
                        }
          end
          if always_trigger == 'true'
            always_trigger_list_item = {}
            if always_trigger_recipients_list == ""
              always_trigger_list_item["recipientList"] = {}
            else
              always_trigger_list_item["recipientList"] = always_trigger_recipients_list
            end
            triggers["hudson.plugins.emailext.plugins.trigger.AlwaysTrigger"] = {
                    "email" => {
                        "recipientList"      =>always_trigger_list_item["recipientList"],
                        "subject"            => "$PROJECT_DEFAULT_SUBJECT",
                        "body"               => "$PROJECT_DEFAULT_CONTENT",
                        "recipientProviders" => {
                            "hudson.plugins.emailext.plugins.recipients.ListRecipientProvider" => {}
                        },
                        "attachmentsPattern" => {},
                        "attachBuildLog"     => "false",
                        "compressBuildLog"   => "false",
                        "replyTo"            => "$PROJECT_DEFAULT_REPLYTO",
                        "contentType"        => "project"
                   }
            }
          end

          job.configuration['publishers'].deep_merge!({
            "hudson.plugins.emailext.ExtendedEmailPublisher"                   => {
              "recipientList"      => recipients_list,
              "configuredTriggers" => triggers,
            "contentType"        => "text/html",
            "defaultSubject"     => subject,
            "defaultContent"     => content,
            "attachmentsPattern" => {},
            "presendScript"      => "$DEFAULT_PRESEND_SCRIPT",
            "postsendScript"     => "$DEFAULT_POSTSEND_SCRIPT",
            "attachBuildLog"     => "false",
            "compressBuildLog"   => "false",
            "replyTo"            => "$DEFAULT_REPLYTO",
            "saveOutput"         => "false",
            "disabled"           => "false"

        }

          })
        end

      end
    end
  end
end
