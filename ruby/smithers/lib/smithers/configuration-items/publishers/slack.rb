
module Smithers
  module ConfigurationItems
    class Publishers
      class Slack
        include LoggingHelper::LogToTerminal
        include Attributes::Mixin::Method
        extend Plugin::Registrar::Registrant

        register :job_publishers, :slack, self.inspect

        attr_reader :job, :configuration_block

        def initialize(job, parent, &block)
          @job = job
          @configuration_block = block

          set_defaults
        end

        attr_method :auth_token, :build_server_url, :room

        attr_method :team_domain
        attr_method(
          {
            start_notification: 'true'
          },
          {
            notify_success: 'true'
          },
          {
            notify_aborted: 'true'
          },
          {
            notify_not_build: 'true'
          },
          {
            notify_unstable: 'true'
          },
          {
            notify_failure: 'true'
          },
          {
            notify_back_to_normal: 'true'
          },
          {
            notify_repeated_failure: 'true'
          },
          {
            include_test_summary: 'false'
          },
          {
            commit_info_choice: 'NONE'
          },
          {
            include_custom_message: 'false'
          },
          {
            custom_message: {}
          }
        )

        def configure
          instance_exec(&configuration_block)

          job.configuration['publishers'].deep_merge!({
            "jenkins.plugins.slack.SlackNotifier" => {
              "teamDomain"            => team_domain,
              "authToken"             => auth_token,
              "buildServerUrl"        => build_server_url,
              "room"                  => room,
              "startNotification"     => start_notification,
              "notifySuccess"         => notify_success,
              "notifyAborted"         => notify_aborted,
              "notifyNotBuilt"        => notify_not_build,
              "notifyUnstable"        => notify_unstable,
              "notifyFailure"         => notify_failure,
              "notifyBackToNormal"    => notify_back_to_normal,
              "notifyRepeatedFailure" => notify_repeated_failure,
              "includeTestSummary"    => include_test_summary,
              "commitInfoChoice"      => commit_info_choice,
              "includeCustomMessage"  => include_custom_message,
              "customMessage"         => custom_message
            }
          })
        end

      end
    end
  end
end
