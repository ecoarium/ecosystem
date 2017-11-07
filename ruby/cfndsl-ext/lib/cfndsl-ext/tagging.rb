
module CfndslExt
  class Tagging
    class << self

      def generate_name(short_name=$WORKSPACE_SETTINGS[:workspace_setting])
        jenkins_job = ENV['JOB_NAME']
        unless jenkins_job.nil?
          return [short_name, jenkins_job].join($WORKSPACE_SETTINGS[:delimiter])
        end

        [
          short_name.gsub(/_/, '-'),
          Git.user.gsub(/\s+/, '-'),
          $WORKSPACE_SETTINGS[:project][:name],
        ].join($WORKSPACE_SETTINGS[:delimiter])
      end

    	def generate_tags(short_name: $WORKSPACE_SETTINGS[:workspace_setting], extra_tags: nil)
        node_name = ENV['NODE_NAME'] || 'NOT_JENKINS'
        jenkins_job = ENV['JOB_NAME'] || 'NOT_JENKINS'

        date_format = "%m/%d/%Y %H:%M:%S"
        date_modified = Time.new.getlocal.strftime(date_format)

        tags = {
          "Name" => generate_name(short_name),
          "Jenkins_Job" => jenkins_job,
          "Node_Name" => node_name,
          "Project" => $WORKSPACE_SETTINGS[:project][:name],
          "Branch" => Git.branch_name,
          "User" => Git.user,
          "User_Email" => Git.user_email,
          "Date_Modified" => date_modified
        }

        unless extra_tags.nil?
          extra_tags.each do |name, value|
            tags[name] = value
          end
        end

        tags_to_array(tags)
      end

      def tags_to_array(tags)
        array = [ ]
        tags.each do |key, value|
          array << { key: key, value: value}
        end
        array
      end

    end
  end
end
