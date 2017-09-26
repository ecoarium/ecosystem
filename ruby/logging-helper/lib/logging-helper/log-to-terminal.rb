
module LoggingHelper
  module LogToTerminal

  	def self.included(receiver)
			receiver.send :include, LogToTerminalMethods
		end

		def self.extended(receiver)
			receiver.extend         LogToTerminalMethods
		end

		module LogToTerminalMethods
			def divider
				if @divider.nil?
					@divider =  "####################################################################################################"
				end
				@divider
			end

	    def info(message=nil, &block)
	      log(message, :info, &block) unless self.silent_info?
	    end

	    def good(message=nil, &block)
	      log(message, :stdout, &block) unless self.silent_info?
	    end

	    def warn(message=nil, &block)
	      log(message, :warn, &block) unless self.silent_warnings?
	    end

      def todo(message, datetime)
        time_bomb(datetime, message)
        warn "#{message}:
#{caller[0]}"
      end

	    def error(message=nil, &block)
	      log(message, :error, &block) unless self.silent_errors?
	    end

	    def debug(message=nil, &block)
	    	log(message, :debug, &block) unless self.silent_debug?
	    end

	    def logger_debug(message=nil, &block)
	    	log(message, :logger_debug, &block) unless self.silent_logger_debug?
	    end

	    def log(message=nil, message_log_level=::LoggingHelper::Util::logging_config::DEFAULT_LOG_LEVEL_SYMBOL, &block)
	    	formatter.log(message, message_log_level, &block)
	    end

      def report_progress(progress, total, show_parts=true)
        if total && total > 0
          percent = (progress.to_f / total.to_f) * 100
          line    = "Progress: #{percent.to_i}%"
          line   << " (#{progress} / #{total})" if show_parts
        else
          line    = "Progress: #{progress}"
        end

        formatter.stdout.write(line)
      end

      def clear_line
        # See: http://en.wikipedia.org/wiki/ANSI_escape_code
        reset = "\r\033[K"

        formatter.stdout.write(reset)
      end

			def silent_info?
				logging_config.audible_info
			end

	    def silence_info()
	    	old_audible_info = logging_config.audible_info
        logging_config.audible_info = true
        yield
      ensure
        logging_config.audible_info = old_audible_info
      end

			def silent_warnings?
				logging_config.audible_warnings
			end

	    def silence_warnings()
	    	old_audible_warnings = logging_config.audible_warnings
        logging_config.audible_warnings = true
        yield
      ensure
        logging_config.audible_warnings = old_audible_warnings
      end

			def silent_errors?
				logging_config.audible_errors
			end

	    def silence_errors()
	    	old_audible_errors = logging_config.audible_errors
        logging_config.audible_errors = true
        yield
      ensure
        logging_config.audible_errors = old_audible_errors
      end

			def silent_debug?
				logging_config.audible_debug
			end

	    def silence_debug()
	    	old_audible_debug = logging_config.audible_debug
        logging_config.audible_debug = true
        yield
      ensure
        logging_config.audible_debug = old_audible_debug
      end

			def silent_logger_debug?
				logging_config.audible_logger_debug
			end

	    def silence_logger_debug()
	    	old_audible_logger_debug = logging_config.audible_logger_debug
        logging_config.audible_logger_debug = true
        yield
      ensure
        logging_config.audible_logger_debug = old_audible_logger_debug
      end

	    @formatter = nil
	    def formatter
	    	return @formatter unless @formatter.nil?
	    	@formatter = ::LoggingHelper::Util::Interceptor.formatter
	    end

	    @logging_config = nil
	    def logging_config
	    	return @logging_config unless @logging_config.nil?
	    	@logging_config = formatter.config
	    end

	  end

		class Logger
			extend LoggingHelper::LogToTerminal::LogToTerminalMethods
		end
	end
end
