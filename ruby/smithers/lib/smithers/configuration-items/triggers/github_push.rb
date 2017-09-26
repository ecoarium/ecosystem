

module Smithers
  module ConfigurationItems
    class Triggers
      class GithubPush
        include LoggingHelper::LogToTerminal
        include Attributes::Mixin::Method
        extend Plugin::Registrar::Registrant

        register :job_triggers, :github_push, self.inspect

        attr_reader :job, :configuration_block

        def initialize(job, parent, &block)
          @job = job
          @configuration_block = block
        end

        def set_to_every_minute
          set_defaults
        end

        def configure
          instance_exec(&configuration_block)

          job.configuration['triggers'].deep_merge!({
            "com.cloudbees.jenkins.GitHubPushTrigger" => {
              "@plugin" => "github@1.25.0",
              "spec"    => {}
            }
          })

          job.instance_exec{
            properties do
              github_project do
                project_url "https://github.com/#{Smithers::Environment.organization_name}/#{Smithers::Environment.project_name}"
              end
            end
          }
        end

      end
    end
  end
end
