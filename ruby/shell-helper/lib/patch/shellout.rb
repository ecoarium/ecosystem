
module Mixlib
  class ShellOut

  	def run_command
      if logger
        log_message = (log_tag.nil? ? "" : "#@log_tag ") << "sh(#@command)"
        logger.log(log_message, log_level)
      end
      super
    end

    def format_for_exception
    	msg = ""
    	if live_stdout.nil? and live_stderr.nil?
        msg << "#{@terminate_reason}\n" if @terminate_reason
        msg << "---- Begin output of #{command} ----\n"
        msg << "STDOUT: #{stdout.strip}\n"
        msg << "STDERR: #{stderr.strip}\n"
        msg << "---- End output of #{command} ----\n"
      elsif live_stdout.nil?
        msg << "#{@terminate_reason}\n" if @terminate_reason
        msg << "---- Begin output of #{command} ----\n"
        msg << "STDOUT: #{stdout.strip}\n"
        msg << "---- End output of #{command} ----\n"
      elsif live_stderr.nil?
        msg << "#{@terminate_reason}\n" if @terminate_reason
        msg << "---- Begin output of #{command} ----\n"
        msg << "STDERR: #{stderr.strip}\n"
        msg << "---- End output of #{command} ----\n"
			else
        msg << "See output from command above\n"
	    end

	    msg << "Ran #{command} returned #{status.exitstatus}" if status
      msg
    end

  end
end
