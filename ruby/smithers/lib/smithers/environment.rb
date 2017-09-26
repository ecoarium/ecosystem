require 'git'

module Smithers
  class Environment
    class << self

      @@jenkins_client = nil
      def jenkins_client=(value)
        @@jenkins_client = value
      end
      def jenkins_client
        @@jenkins_client
      end

      @@jenkins_url = nil
      def jenkins_url=(value)
        @@jenkins_url = value
      end
      def jenkins_url
        @@jenkins_url
      end

      @@jobs = {}
      def jobs=(value)
        @@jobs = value
      end
      def jobs
        @@jobs
      end

      def down_stream_job_properties_file_path
        $WORKSPACE_SETTINGS[:paths][:project][:jenkins][:down][:stream][:job][:properties][:file][/#{$WORKSPACE_SETTINGS[:paths][:project][:home]}\/(.*)/, 1]
      end

      def organization_name
        $WORKSPACE_SETTINGS[:organization][:name].capitalize
      end

      def project_name
        $WORKSPACE_SETTINGS[:project][:name]
      end

      def branch_name
        Git.branch_name
      end

      def delimiter
        $WORKSPACE_SETTINGS[:delimiter]
      end

    end
  end
end
