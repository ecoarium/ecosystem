
module LoggingHelper
  module Util
  	class Config

  		LOG_LEVELS = {
  			logger_debug: 5,
	    	debug: 4,
	    	info: 3,
	    	stdout: 3,
	    	warn: 2,
	    	error: 1,
	    	stderr: 1,
	    	silent: 0
	    }

	    DEFAULT_LOG_LEVEL_SYMBOL = :info
	    DEFAULT_LOG_LEVEL = LOG_LEVELS[DEFAULT_LOG_LEVEL_SYMBOL]

	    def initialize(initial_log_level)
	    	self.log_level = initial_log_level
	    end

	    def log_level=(value)
	    	@log_level = decode_log_level(value)
	    end

	    def log_level
	    	@log_level
	    end

	    def log_level_as_sym
	    	log_level_to_sym(log_level)
	    end

	    def log_level_to_sym(num)
	    	raise "log_level cannot be nil" if num.nil?
	    	log_level_as_sym = nil
	    	if num.is_a?(Symbol)
	    		bad_log_level(num) if LOG_LEVELS[num].nil?
	    		log_level_as_sym = LOG_LEVELS[num]
	    	elsif value.is_a?(Integer)
	    		log_level_as_sym = LOG_LEVELS.find{|key,value| value == num }
	    		bad_log_level(num) unless log_level_as_sym.nil?
				else
					bad_log_level(num)
	    	end
	    	log_level_as_sym
	    end

	    def decode_log_level(value)
	    	raise "log_level cannot be nil" if value.nil?
	    	if value.is_a?(Symbol)
	    		bad_log_level(value) if LOG_LEVELS[value].nil?
	    		value = LOG_LEVELS[value]
	    	elsif value.is_a?(Integer)
	    		bad_log_level(value) unless LOG_LEVELS.values.include?(value)
				else
					bad_log_level(value)
	    	end
	    	value
	    end

	    def bad_log_level(value)
	    	raise %/#{value.inspect} is not a valid log_level.
Please choose one of the following:
#{LOG_LEVELS.keys.collect{|level| level.inspect}.join("\n")}/
	    end

	    @audible_info = false
	    def audible_info
	    	@audible_info
	    end

	    def audible_info=(value)
	    	@audible_info = value
	    end
	    
	    @audible_warnings = false
	    def audible_warnings
	    	@audible_warnings
	    end

	    def audible_warnings=(value)
	    	@audible_warnings = value
	    end

	    @audible_errors = false
	    def audible_errors
	    	@audible_errors
	    end

	    def audible_errors=(value)
	    	@audible_errors = value
	    end

	    @audible_stderr = false
	    def audible_stderr
	    	@audible_stderr
	    end

	    def audible_stderr=(value)
	    	@audible_stderr = value
	    end

	    @audible_stdout = false
	    def audible_stdout
	    	@audible_stdout
	    end

	    def audible_stdout=(value)
	    	@audible_stdout = value
	    end

	    @audible_debug = false
	    def audible_debug
	    	@audible_debug
	    end

	    def audible_debug=(value)
	    	@audible_debug = value
	    end

	    @audible_logger_debug = false
	    def audible_logger_debug
	    	@audible_logger_debug
	    end

	    def audible_logger_debug=(value)
	    	@audible_logger_debug = value
	    end
	  end
	end
end
