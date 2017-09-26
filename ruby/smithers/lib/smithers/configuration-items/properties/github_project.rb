
module Smithers
  module ConfigurationItems
    class Properties
      class GithubProject
        include LoggingHelper::LogToTerminal
        include Attributes::Mixin::Method
        extend Plugin::Registrar::Registrant

        register :job_properties, :github_project, self.inspect

        attr_reader :job, :configuration_block

        def initialize(job, parent, &block)
          @job = job
          @configuration_block = block
        end
        
        attr_method :project_url


        
        def configure
          instance_exec(&configuration_block)

          job.configuration['properties'].deep_merge!({
            'com.coravy.hudson.plugins.github.GithubProjectProperty' => {
            '@plugin'     => 'github@1.25.0',
            'projectUrl'  => project_url,
            'displayName' => {}
              }
            }
          )
        end

      end
    end
  end
end
