
module Smithers
  module ConfigurationItems
    class Publishers
      class Groovy
        include LoggingHelper::LogToTerminal
        include Attributes::Mixin::Method
        extend Plugin::Registrar::Registrant

        register :job_publishers, :groovy, self.inspect

        attr_reader :job, :configuration_block

        def initialize(job, parent, &block)
          @job = job
          @configuration_block = block
        end
        
        attr_method :script
        
        def configure
          instance_exec(&configuration_block)

          job.configuration['publishers'].deep_merge!({
            'org.jvnet.hudson.plugins.groovypostbuild.GroovyPostbuildRecorder' => {
              'script' => {
                'sandbox' => false
              },
              'behavior' => 0,
              'runForMatrixParent' => false
            }
          })

          script_container = job.configuration['publishers']['org.jvnet.hudson.plugins.groovypostbuild.GroovyPostbuildRecorder']['script']

          if script_container['script'].nil?
            script_container['script'] = script
          else
            script_container['script'] = [
              script_container['script'],
              script
            ].join("
/* ------------------SCRIPT DIVIDER------------------- */
")
          end
        end

      end
    end
  end
end