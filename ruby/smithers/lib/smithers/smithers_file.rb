
module Smithers
  class SmithersFile
    include LoggingHelper::LogToTerminal
    include Plugin::MethodMissingIntercept::Flexible

    attr_reader :smithers_file_path, :to_stdout

    def initialize(opts={})
      opts.each{|opt_name, opt_value|
        instance_variable_set("@#{opt_name}".to_sym, opt_value) if respond_to?(opt_name.to_s.to_sym)
      }

      Environment.jobs = {}

      Environment.jenkins_url = opts[:jenkins_url]

      Environment.jenkins_client = JenkinsApi::Client.new(
        server_url: opts[:jenkins_url],
        ssl: opts[:jenkins_ssl],
        username: opts[:jenkins_username],
        password: opts[:jenkins_password],
        log_level: $WORKSPACE_SETTINGS[:logging][:log_level] == 'debug' ? 0 : 1
      )
    end

    attr_reader :included_smithers_files

    def include_smithers_file(file_path)
      file_path = File.expand_path(file_path)
      @included_smithers_files = [] if @included_smithers_files.nil?
      return if included_smithers_files.include?(file_path)

      debug { "including smithers file: #{file_path}" }
      raise "smithers file does not exist: #{file_path}" unless File.exist?(file_path)
      @included_smithers_files << file_path
      self.instance_eval(File.read(file_path), file_path, 1)
    end

    def run
      include_smithers_file(smithers_file_path)

      client_job_manager = Environment.jenkins_client.job
      Environment.jobs.each{|job_short_name, job|
        if to_stdout
          puts "
(((((((((((((((((### BEGIN #{job.name.upcase} ###)))))))))))))))))
#{job.xml}
(((((((((((((((((### END #{job.name.upcase} ###)))))))))))))))))
"
          next
        end

        job_already_existed = client_job_manager.exists?(job.name)
        disable_job = true
        if job_already_existed
          job_config_as_xml = client_job_manager.get_config(job.name)
          job_config = XmlSimple.xml_in(job_config_as_xml, {
            'ForceArray' => false, 'AttrPrefix' => true
          })

          disable_job = eval(job_config['disabled']) == true
        end

        debug {"
(((((((((((((((((### BEGIN #{job.name.upcase} ###)))))))))))))))))
#{job.xml}
(((((((((((((((((### END #{job.name.upcase} ###)))))))))))))))))
"}
        client_job_manager.create_or_update(job.name, job.xml)

        client_job_manager.enable(job.name) unless disable_job
      }
    end

    def registry_name
      :job
    end

    def plugin_action_method_name
      :configure
    end

  end
end