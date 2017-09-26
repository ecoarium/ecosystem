
module Smithers
  module ConfigurationItems
    class Properties
      class Parameters
        class UpstreamParameter
          include LoggingHelper::LogToTerminal
          include Attributes::Mixin::Method
          extend Plugin::Registrar::Registrant

          register :job_parameters, :upstream_parameter, self.inspect

          attr_reader :job, :parent, :configuration_block

          def initialize(job, parent, &block)
            @job = job
            @parent = parent
            @configuration_block = block
          end
          
          attr_method :name, :description, :upstream_job_name
          
          def configure
            instance_exec(&configuration_block)

            parent.instance_exec(self){|me|
              extensible do
                name me.name
                description me.description
                script %^
def getParameterValue(parameterName, buildResult) {
  buildResult.action.parameter.find{ param ->
    param.name.text() == parameterName
  }.value.text()
}

def slurper = new XmlSlurper()
def buildResults = slurper.parse("#{Smithers::Environment.jenkins_url}/job/#{Smithers::Environment.project_name}#{Smithers::Environment.delimiter}#{Smithers::Environment.branch_name}#{Smithers::Environment.delimiter}#{me.upstream_job_name}/api/xml?depth=1&tree=builds[result,actions[parameters[name,value]]]{,30}")

buildVersions = []

buildResults.build.each{ buildResult ->
  if (buildResult.result.text() != 'SUCCESS')
    return
  buildVersions << getParameterValue('#{me.name}', buildResult)
}

buildVersions.unique()
^
              end
            }
          end

        end
      end
    end
  end
end