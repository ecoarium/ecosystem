require 'json'

module CfndslExt
  class Reporter
    class << self

      def load_resources_report
        $WORKSPACE_SETTINGS[:aws_resources_report] = {}

        report_path = "#{$WORKSPACE_SETTINGS[:paths][:project][:deploy][:cfndsl][:state]}/report.json"

        if File.exist?(report_path)
          $WORKSPACE_SETTINGS[:aws_resources_report] = JSON.parse(File.read(report_path),:symbolize_names => true)
        end
      end
      
    end
  end
end
