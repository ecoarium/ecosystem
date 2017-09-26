class IO
	class Wrapper
		module Deligate
			attr_reader :original
			attr_accessor :wrapped
		end
		class << self

			def intercept_stdout(wrapper)
				$stdout.sync = true
				@stdout = $stdout
				stdout_wrapper = IO::Wrapper.new(@stdout, wrapper)
				wrapper.wrapped = stdout_wrapper
				$stdout = stdout_wrapper
			end

			def intercept_stderr(wrapper)
				$stderr.sync = true
				@stderr = $stderr
				stderr_wrapper = IO::Wrapper.new(@stderr, wrapper)
				wrapper.wrapped = stderr_wrapper
				$stderr = stderr_wrapper
			end

			def stdout
				@stdout = $stdout if @stdout.nil?
				@stdout
			end

			def stderr
				@stderr = $stderr if @stderr.nil?
				@stderr
			end

		end

		def initialize(original, wrapper)
			@original = original
			@wrapper = wrapper
			wrapper.instance_variable_set(:@original, @original)
		end

		def method_missing(method_symbol, *args, &block)
			if wrapper.respond_to?(method_symbol)
				#original.puts("calling on wrapper.#{method_symbol}(#{args.inspect})")
				return wrapper.method(method_symbol).call(*args, &block)
			end
			#original.puts("pass through to original.#{method_symbol}(#{args.inspect})")
			original.method(method_symbol).call(*args, &block)
		end

		def respond_to_missing?(name, include_private = false)
	    original.respond_to?(name, include_private)
	  end

		def stdout
			self.class.stdout
		end

		def stderr
			self.class.stderr
		end

		def reinstate_stdout
			$stdout = stdout
		end

		def reinstate_stderr
			$stderr = stderr
		end

		def wrap_stdout
			$stdout = wrapped
		end

		def wrap_stderr
			$stderr = wrapped
		end
		

	  private

		attr_reader :original, :wrapper

	end
end