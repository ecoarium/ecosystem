

module Smithers
  module ConfigurationItems
    class Scm
      class Git
        include LoggingHelper::LogToTerminal
        include Attributes::Mixin::Method
        extend Plugin::Registrar::Registrant

        register :job_scm, :git, self.inspect

        attr_reader :job, :configuration_block

        def initialize(job, parent, &block)
          @job = job
          @configuration_block = block
          set_defaults
        end

        attr_method :credentials_id
        attr_method :ref_spec
        attr_method :included_regions, :excluded_regions
        attr_method :prune_stale_branches
        attr_method :commit_hash
        attr_method :branch_specifier
        attr_method(
          {
            repo_name: Smithers::Environment.project_name
          },
          {
            organization_name: Smithers::Environment.organization_name
          },
          {
            branch_name: Smithers::Environment.branch_name
          },
          {
            git_tool: 'Default'
          }
        )



        def configure
          instance_exec(&configuration_block)

          job.configuration['scm'] = {
            '@class' => 'hudson.plugins.git.GitSCM',
            'configVersion' => '2',
            'userRemoteConfigs' => {
              'hudson.plugins.git.UserRemoteConfig' => {
                'url' => "https://github.com/#{organization_name}/#{repo_name}.git"
              }
            },
            'branches' => {
              'hudson.plugins.git.BranchSpec' => {}
            },
            'doGenerateSubmoduleConfigurations' => 'false',
            'gitTool' => git_tool,
            'browser' => {
              '@class' => 'hudson.plugins.git.browser.GithubWeb',
              'url' => "https://github.com/#{organization_name}/#{repo_name}"
            },
            'submoduleCfg' => {
              '@class' => 'list'
            },
            'extensions' => {}
          } if job.configuration['scm']['@class'].nil?

          job.configuration['scm']['branches']['hudson.plugins.git.BranchSpec']['name'] = branch_specifier || branch_name unless branch_name.nil? && branch_specifier.nil?

          job.configuration['scm']['userRemoteConfigs']['hudson.plugins.git.UserRemoteConfig']['credentialsId'] = credentials_id unless credentials_id.nil?

          job.configuration['scm']['userRemoteConfigs']['hudson.plugins.git.UserRemoteConfig']['refspec'] = ref_spec unless ref_spec.nil?

          job.configuration['scm']['extensions']['hudson.plugins.git.extensions.impl.PruneStaleBranch'] = {} unless prune_stale_branches.nil?

          job.configuration['scm']['extensions']['hudson.plugins.git.extensions.impl.LocalBranch'] = {
            'localBranch' => commit_hash
          } unless commit_hash.nil?

          if !included_regions.nil? || !excluded_regions.nil?
            job.configuration['scm']['extensions']['hudson.plugins.git.extensions.impl.PathRestriction'] = {}

            job.configuration['scm']['extensions']['hudson.plugins.git.extensions.impl.PathRestriction']['includedRegions'] = included_regions unless included_regions.nil?

            job.configuration['scm']['extensions']['hudson.plugins.git.extensions.impl.PathRestriction']['excludedRegions'] = excluded_regions unless excluded_regions.nil?
          end
        end

      end
    end
  end
end
