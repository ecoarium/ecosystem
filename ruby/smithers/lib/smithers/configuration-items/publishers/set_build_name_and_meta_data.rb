
module Smithers
  module ConfigurationItems
    class Publishers
      class SetBuildNameAndMetaData
        include LoggingHelper::LogToTerminal
        include Attributes::Mixin::Method
        extend Plugin::Registrar::Registrant

        register :job_publishers, :set_build_name_and_meta_data, self.inspect

        attr_reader :job, :parent, :configuration_block

        def initialize(job, parent, &block)
          @job = job
          @parent = parent
          @configuration_block = block
        end

        def configure
          parent.instance_exec{
            groovy do
              script %|
import hudson.model.*
import hudson.util.*

application_version  = "unknown"
commit_hash = "unknown"

matcher = manager.getMatcher(manager.build.logFile, /^APPLICATION_VERSION=(.*)$/)
if(matcher != null && matcher[0] != null && matcher[0][1] != null) {
  application_version = matcher.group(1)
}

matcher = manager.getMatcher(manager.build.logFile, /^APPLICATION_COMMIT_HASH=(.*)$/)
if(matcher != null && matcher[0] != null && matcher[0][1] != null) {
  commit_hash = matcher.group(1)
}

manager.build.setDisplayName(application_version)

def paramAction = new ParametersAction(
  new StringParameterValue('APPLICATION_VERSION', application_version),
  new StringParameterValue('APPLICATION_COMMIT_HASH', commit_hash),
  new StringParameterValue('BUILD_RESULT', manager.getResult())
)

manager.build.addAction(paramAction)
|
            end
          }
        end

      end
    end
  end
end
