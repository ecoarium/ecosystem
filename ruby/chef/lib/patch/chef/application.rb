
class Chef
  class Application
    def apply_config(config_content, config_file_path)
      Chef::Config.from_string(config_content, config_file_path)
    rescue Exception => error
      Chef::Application.fatal!("#{error.message}:\n  #{error.backtrace.join("\n  ")}", 2)
    end
  end
end