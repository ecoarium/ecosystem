
require 'log4r'
require "log4r/outputter/outputter"
require "log4r/staticlogger"


module LoggingHelper
  class Log4r
    class << self

      def add_outputters(logger)
        require 'log4r/config'
        ::Log4r.define_levels(*::Log4r::Log4rConfig::LogLevels)

        Outputter.new(:debug, formatter: StringFormatter)
        ::Log4r::Outputter[:debug].only_at ::Log4r::DEBUG
        logger.add ::Log4r::Outputter[:debug]

        Outputter.new(:warn, formatter: StringFormatter)
        ::Log4r::Outputter[:warn].only_at ::Log4r::WARN
        logger.add ::Log4r::Outputter[:warn]

        Outputter.new(:error, formatter: StringFormatter)
        ::Log4r::Outputter[:error].only_at ::Log4r::ERROR, ::Log4r::FATAL
        logger.add ::Log4r::Outputter[:error]

        Outputter.new(:info, formatter: StringFormatter)
        ::Log4r::Outputter[:info].only_at ::Log4r::INFO
        logger.add ::Log4r::Outputter[:info]
      end

    end

    class StringFormatter < ::Log4r::Formatter
      def format(event)
        event.data
      end
    end

    class Outputter < ::Log4r::Outputter

      attr_reader :log_at_level
      
      def initialize(log_at_level, hash={})
        super(log_at_level, hash)
        @log_at_level = log_at_level
      end

      private
      
      def write(message)
        ::LoggingHelper::LogToTerminal::Logger.log(message, log_at_level)
      end

    end
  end
end