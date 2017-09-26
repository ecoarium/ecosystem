module Smithers
  module ConfigurationItems
    class Publishers
      class Findbugs
        include LoggingHelper::LogToTerminal
        include Attributes::Mixin::Method
        extend Plugin::Registrar::Registrant

        register :job_publishers, :findbugs, self.inspect

        attr_reader :job, :configuration_block

        def initialize(job, parent, &block)
          @job = job
          @configuration_block = block

          set_defaults
        end

        # attr_method :auth_token, :build_server_url, :room // make the variable required

        attr_method(
          {
            pattern: "production/**/.build/reports/findbugs/main.xml"
          },
          {
            is_rank_activated: 'true'
          }
        )


        def configure
          instance_exec(&configuration_block)

          job.configuration['publishers'].deep_merge!({
             "hudson.plugins.findbugs.FindBugsPublisher"  => {
               "healthy"                     => {},
               "unHealthy"                   => {},
               "thresholdLimit"              => "low",
               "pluginName"                  => "[FINDBUGS] ",
               "defaultEncoding"             => {},
               "canRunOnFailed"              => "false",
               "usePreviousBuildAsReference" => "false",
               "useStableBuildAsReference"   => "false",
               "useDeltaValues"              => "false",
               "thresholds"                  => {
                 "unstableTotalAll"    => {},
                 "unstableTotalHigh"   => {},
                 "unstableTotalNormal" => {},
                 "unstableTotalLow"    => {},
                 "unstableNewAll"      => {},
                 "unstableNewHigh"     => {},
                 "unstableNewNormal"   => {},
                 "unstableNewLow"      => {},
                 "failedTotalAll"      => {},
                 "failedTotalHigh"     => {},
                 "failedTotalNormal"   => {},
                 "failedTotalLow"      => {},
                 "failedNewAll"        => {},
                 "failedNewHigh"       => {},
                 "failedNewNormal"     => {},
                 "failedNewLow"        => {}
               },
               "shouldDetectModules"         => "false",
               "dontComputeNew"              => "true",
               "doNotResolveRelativePaths"   => "false",
               "pattern"                     => pattern,
               "isRankActivated"             => is_rank_activated,
               "excludePattern"              => {},
               "includePattern"              => {}
            }
          })
        end
      end
    end
  end
end
