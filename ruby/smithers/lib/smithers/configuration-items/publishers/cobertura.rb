
module Smithers
  module ConfigurationItems
    class Publishers
      class Cobertura
        include LoggingHelper::LogToTerminal
        include Attributes::Mixin::Method
        extend Plugin::Registrar::Registrant

        register :job_publishers, :cobertura, self.inspect

        attr_reader :job, :parent, :configuration_block

        def initialize(job, parent, &block)
          @job = job
          @parent = parent
          @configuration_block = block

          set_defaults
        end

        attr_method({
          result_glob_path: 'production/**/.build/reports/coverage/coverage.xml'
        })

        def configure
          instance_exec(&configuration_block)

          job.configuration['publishers'].deep_merge!({
            "hudson.plugins.cobertura.CoberturaPublisher" => {
              "coberturaReportFile" => result_glob_path,
              "onlyStable"          => "false",
              "failUnhealthy"       => "false",
              "failUnstable"        => "false",
              "autoUpdateHealth"    => "false",
              "autoUpdateStability" => "false",
              "zoomCoverageChart"   => "false",
              "maxNumberOfBuilds"   => "0",
              "failNoReports"       => "true",
              "healthyTarget"       => {
                "targets" => {
                  "@class"     => "enum-map",
                  "@enum-type" => "hudson.plugins.cobertura.targets.CoverageMetric"
                }
              },
              "unhealthyTarget"  => {
                "targets" => {
                  "@class"     => "enum-map",
                  "@enum-type" => "hudson.plugins.cobertura.targets.CoverageMetric"
                }
              },
              "failingTarget" => {
                "targets" => {
                  "@class"     => "enum-map",
                  "@enum-type" => "hudson.plugins.cobertura.targets.CoverageMetric"
                }
              },
              "sourceEncoding" => "ASCII"
            }
          })

          
          
          parent.instance_exec{
            coverage_report_name = 'Detailed Code Coverage Report'

            html do
              report_name coverage_report_name
              report_directory_path 'production/.build/reports/coverage'
              index_file_name 'index.html'
            end
            groovy do
              script %^
import hudson.model.*
import hudson.util.*

def buildNumber = manager.build.number
def codeCoverageURL = "#{Smithers::Environment.jenkins_url}/job/#{job.name}/${buildNumber}/#{coverage_report_name.gsub(/\s+/,'_')}/coverage.xml"

paramAction = new ParametersAction(
  new StringParameterValue('COBERTURA_FILE_URL', codeCoverageURL)
)

manager.build.addAction(paramAction)

^
            end
          }
        end

      end
    end
  end
end
