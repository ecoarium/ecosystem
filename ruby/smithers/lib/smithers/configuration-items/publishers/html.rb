
module Smithers
  module ConfigurationItems
    class Publishers
      class HTML
        include LoggingHelper::LogToTerminal
        include Attributes::Mixin::Method
        extend Plugin::Registrar::Registrant

        register :job_publishers, :html, self.inspect

        attr_reader :job, :configuration_block

        def initialize(job, parent, &block)
          @job = job
          @configuration_block = block
        end
        
        attr_method :report_name, :report_directory_path, :index_file_name
        
        def configure
          instance_exec(&configuration_block)

          job.configuration['publishers']['htmlpublisher.HtmlPublisher'] = {
            'reportTargets' => {
              'htmlpublisher.HtmlPublisherTarget' => []
            }
          } if job.configuration['publishers']['htmlpublisher.HtmlPublisher'].nil?

          job.configuration['publishers']['htmlpublisher.HtmlPublisher']['reportTargets']['htmlpublisher.HtmlPublisherTarget'].push(
            {
              'reportName'            => report_name,
              'reportDir'             => report_directory_path,
              'reportFiles'           => index_file_name,
              'alwaysLinkToLastBuild' => false,
              'keepAll'               => true,
              'allowMissing'          => true
            }
          )
        end

      end
    end
  end
end