require 'thread'
require 'io/wrapper'

module LoggingHelper
	module Util
		class Interceptor
			class << self

				@@stdout_interceptor = nil
				@@stderr_interceptor = nil
				@@formatter = nil

				def intercept(opts={})
					opts = {
				 		stdout_log_level: :info,
				 		stderr_log_level: :error,
				 		log_level: Config::DEFAULT_LOG_LEVEL_SYMBOL
				 	}.merge(opts)

				 	@@formatter = Formatter.new($stdout, $stderr, opts[:log_level])

					@@stdout_interceptor = new(opts[:stdout_log_level])
					@@stderr_interceptor = new(opts[:stderr_log_level])

					IO::Wrapper.intercept_stdout(@@stdout_interceptor)
					IO::Wrapper.intercept_stderr(@@stderr_interceptor)
		    end

		    def formatter
		    	@@formatter
		    end

		    def stdout_interceptor
		    	@@stdout_interceptor
		    end

		    def stderr_interceptor
		    	@@stderr_interceptor
		    end
			end

			include IO::Wrapper::Deligate

			attr_reader :log_level

			def initialize(log_level)
				self.class.formatter.config.decode_log_level(log_level)

				@log_level = log_level
			end

			def puts(*messages)
				messages.each{|message|
					self.class.formatter.log(message, log_level)
				}
			end

			def print(*args)
				message = args.join("#{$,}") + "#{$\}"
				self.class.formatter.log(message, log_level)
			end

			def printf(format_string, *args)
				message = sprintf(format_string, *args)
				self.class.formatter.log(message, log_level)
			end

			def write(message)
				self.class.formatter.log(message, log_level, false)
			end

			def ==(other)
			  other == wrapped.stdout or other == wrapped.stderr
			end

			def <<(chunk)
				write(chunk)
			end

			private

			def id
				"#{Thread.current.inspect}#{$WORKSPACE_SETTINGS[:delimiter]}#{Process.pid}"
			end

		end
	end
end
