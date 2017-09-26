
module Smithers
  module ConfigurationItems
    class Builders
      class AnsiColor
        include LoggingHelper::LogToTerminal
        include Attributes::Mixin::Method
        extend Plugin::Registrar::Registrant

        register :job_build_wrappers, :ansicolor, self.inspect

        attr_reader :job, :configuration_block

        def initialize(job, parent, &block)
          @job = job
          @configuration_block = block
        end
        
        def configure
          instance_exec(&configuration_block)

          job.configuration['buildWrappers'].deep_merge!({
            "hudson.plugins.ansicolor.AnsiColorBuildWrapper" => {
              "colorMapName" => "xterm"
            }
          })
        end

      end
    end
  end
end