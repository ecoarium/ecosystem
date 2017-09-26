require 'resource'

module Smithers
  module ConfigurationItems
    class Triggers
      class PullRequestBuilder
        include LoggingHelper::LogToTerminal
        include Attributes::Mixin::Method
        include Resource
        extend Plugin::Registrar::Registrant

        register :job_triggers, :pull_request_builder, self.inspect

        attr_reader :job, :configuration_block, :parent

        def initialize(job, parent, &block)
          @job = job
          @configuration_block = block
          @parent = parent
          set_defaults
        end

        attr_method(
          {
            orgslist: $WORKSPACE_SETTINGS[:organization][:name]
          },
          {
            use_github_hooks: true
          },
          {
            whitelist_branch: Environment.branch_name
          },
          {
            commit_status_context: 'ecosystem-premerge-test'
          },
          {
            trigger_phrase: {}
          }
        )

        def configure

          instance_exec(&configuration_block)
          job.configuration['properties'].deep_merge!({
            "hudson.plugins.throttleconcurrents.ThrottleJobProperty" => {
              "@plugin"                       => "throttle-concurrents@1.9.0",
              "maxConcurrentPerNode"          => "0",
              "maxConcurrentTotal"            => "0",
              "categories"                    => {
                "@class" => "java.util.concurrent.CopyOnWriteArrayList"
              },
              "throttleEnabled"               => "false",
              "throttleOption"                => "project",
              "limitOneJobWithMatchingParams" => "false",
              "paramsToUseForLimit"           => {}
            }
          }

          )
          job.configuration['triggers'].deep_merge!({
            'org.jenkinsci.plugins.ghprb.GhprbTrigger' => {
              "@plugin"                              => "ghprb@1.30.8-SNAPSHOT",
              "spec"                                 => "H/5 * * * *",
              "latestVersion"                        => "3",
              "configVersion"                        => "3",
              "adminlist"                            => {},
              "allowMembersOfWhitelistedOrgsAsAdmin" => "false",
              "orgslist"                             => orgslist,
              "cron"                                 => "H/5 * * * *",
              "buildDescTemplate"                    => {},
              "onlyTriggerPhrase"                    => "false",
              "useGitHubHooks"                       => use_github_hooks,
              "permitAll"                            => "false",
              "whitelist"                            => "cp2 yzhai jusun",
              "autoCloseFailedPullRequests"          => "false",
              "displayBuildErrorsOnDownstreamBuilds" => "false",
              "whiteListTargetBranches"              => {
                "org.jenkinsci.plugins.ghprb.GhprbBranch" => {
                  "branch" => whitelist_branch
                }
              },
              "blackListTargetBranches"              => {
                "org.jenkinsci.plugins.ghprb.GhprbBranch" => {
                  "branch" => {}
                }
              },
              "gitHubAuthId"                         => resource('user')[:password],
              "triggerPhrase"                        => trigger_phrase,
              "skipBuildPhrase"                      => ".*\\[skip\\W+ci\\].*",
              "extensions"                           => {
                "org.jenkinsci.plugins.ghprb.extensions.status.GhprbSimpleStatus" => {
                  "commitStatusContext" => commit_status_context,
                  "triggeredStatus"     => {},
                  "startedStatus"       => {},
                  "statusUrl"           => {},
                  "addTestResults"      => "false"
                }
              }
            }
          })

          job.instance_exec{
            properties do
              github_project do
                project_url "https://github.com/#{Smithers::Environment.organization_name}/#{Smithers::Environment.project_name}"
              end
            end

            scm do
              git do
                branch_specifier '${sha1}'
                ref_spec '+refs/pull/*:refs/remotes/origin/pr/*'
              end
            end
          }
        end

      end
    end
  end
end
