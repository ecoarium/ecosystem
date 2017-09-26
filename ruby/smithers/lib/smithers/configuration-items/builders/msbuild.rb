module Smithers
  module ConfigurationItems
    class Builders
      class Msbuild
        include LoggingHelper::LogToTerminal
        include Attributes::Mixin::Method
        extend Plugin::Registrar::Registrant

        register :job_builders, :msbuild, self.inspect

        attr_reader :job, :configuration_block

        def initialize(job, parent, &block)
          @job = job
          @configuration_block = block

          set_defaults
        end

        attr_method :msBuildFile

        attr_method(
          {
            cmdLineArgs: {}
          },
          {
            buildVariablesAsProperties: 'false'
          }
        )

        def configure
          instance_exec(&configuration_block)

          job.configuration['builders'].deep_merge!({
            "hudson.plugins.msbuild.MsBuildBuilder" => {
                  "msBuildName"                => "(Default)",
                  "msBuildFile"                => msBuildFile,
                  "cmdLineArgs"                => cmdLineArgs,
                  "buildVariablesAsProperties" => buildVariablesAsProperties,
                  "continueOnBuildFailure"     => "false",
                  "unstableIfWarnings"         => "false"
                }
          })
        end

      end
    end
  end
end
