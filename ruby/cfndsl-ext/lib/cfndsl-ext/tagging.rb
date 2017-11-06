
module CfndslExt
  class Tagging
    class << self

    	def generate_tags(name:, expiration_hours: 24, persistent: false, extra_tags: nil)
        project = ENV['PROJECT_NAME']

        slave = ENV['NODE_NAME'] || 'NOT_JENKINS'
        jenkins_job = ENV['JOB_NAME'] || 'NOT_JENKINS'
        user = (`git config user.name`).chomp!
        user_email = (`git config user.email`).chomp!

        date_format = "%m/%d/%Y %H:%M:%S"
        date_modified = Time.new.getlocal.strftime(date_format)
        expires = ( Time.new + 3600 * expiration_hours ).getlocal.strftime(date_format)

        tags = {
          "Name" => "#{name}#{$WORKSPACE_SETTINGS[:delimiter]}#{jenkins_job}#{$WORKSPACE_SETTINGS[:delimiter]}#{date_modified}",
          "name" => name,
          "Jenkins_Job" => jenkins_job,
          "Slave" => slave,
          "Project" => project,
          "Branch" => Git.branch_name,
          "User" => user,
          "User_Email" => user_email,
          "Date_Modified" => date_modified,
          "Expires" => expires,
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
