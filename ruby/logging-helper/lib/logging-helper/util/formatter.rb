
module LoggingHelper
  module Util
    class Formatter

      # https://wiki.archlinux.org/index.php/Color_Bash_Prompt
      
      COLORS = {
        :none   => "",
        :clear  => "\e[0m",
        :red    => "\e[31m",
        :green  => "\e[32m",
        :yellow => "\e[33m",
        :blue   => "\e[34;1m"
      }

      attr_reader :stdout, :stderr, :config

      def initialize(stdout, stderr, log_level)
        @stdout = stdout
        @stderr = stderr
        @config = Config.new(log_level)
      end

      def log(message, log_level=Config::DEFAULT_LOG_LEVEL_SYMBOL, new_line=true)
        return unless config.decode_log_level(log_level) <= config.log_level
        color = map_log_level_to_color(log_level)
        
        message = '' if message.nil?

        message_from_block = yield if block_given?

        if message_from_block.is_a?(String)
          message = "#{message}\n#{message_from_block}"
        end

        message = %/
################# LOGGER ID #################
    original: #{ENV['ORIGIN_PROCESS_PID']} -- #{ENV['ORIGIN_THREAD_ID']}"
    current:  #{Process.pid} -- #{Thread.current.inspect}
#############################################

#{message}
/ if config.decode_log_level(log_level) == config.decode_log_level(:logger_debug)

        colorized_message = color_message(color, message)

        case log_level
        when :stderr, 1, :error, :debug, 4, :warn, 2
          begin
            stderr.write colorized_message unless self.silent_stderr?
          rescue
            unless self.silent_stderr?
              stderr.write message rescue false
            end
          end
          stderr.puts '' if new_line
        else
          begin
            stdout.write colorized_message unless self.silent_stdout?
          rescue
            unless self.silent_stdout?
              stdout.write message rescue false
            end
          end
          stdout.puts '' if new_line
        end
      end

      def silent_stderr?
        config.audible_stderr
      end

      def silence_stderr()
        old_audible_stderr = config.audible_stderr
        config.audible_stderr = true
        yield
      ensure
        config.audible_stderr = old_audible_stderr
      end

      def silent_stdout?
        config.audible_stdout
      end

      def silence_stdout()
        old_audible_stdout = config.audible_stdout
        config.audible_stdout = true
        yield
      ensure
        config.audible_stdout = old_audible_stdout
      end

      private

      def map_log_level_to_color(level)
        config.decode_log_level(level)

        case level
        when :stdout
          return :green
        when :stderr, 1, :error
          return :red
        when :warn, 2
          return :yellow
        when :debug, 4
          return :blue
        else
          return :none
        end
      end

      def color_message(color, message)
        "#{COLORS[color]}#{remove_ansi_escape_codes(message)}#{COLORS[:clear]}"
      end

      def remove_ansi_escape_codes(text)
        text = "#{text}"
        # An array of regular expressions which match various kinds
        # of escape sequences. I can't think of a better single regular
        # expression or any faster way to do this.
        matchers = [
          /\e\[\d*[ABCD]/,       # Matches things like \e[4D
          /\e\[(\d*;)?\d*[HF]/,  # Matches \e[1;2H or \e[H
          /\e\[(s|u|2J|K)/,      # Matches \e[s, \e[2J, etc.
          /\e\[=\d*[hl]/,        # Matches \e[=24h
          /\e\[\?[1-9][hl]/,     # Matches \e[?2h
          /\e\[20[hl]/,          # Matches \e[20l]
          /\e[DME78H]/,          # Matches \eD, \eH, etc.
          /\e\[[0-2]?[JK]/,      # Matches \e[0J, \e[K, etc.
        ]

        # Take each matcher and replace it with emptiness.
        matchers.each do |matcher|
          text.gsub!(matcher, "") rescue false
        end

        text
      end
    end
  end
end

