
module LoggingHelper
  class LogToFile
  	include LoggingHelper::LogToTerminal

		def initialize(stdout, stderr, log_level)
			@formatter = Util::Formatter.new(stdout, stderr, log_level)
		end
    
  end
end