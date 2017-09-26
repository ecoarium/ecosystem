require 'log4r'
require 'logging-helper'

# Enable logging if it is requested. We do this before
# anything else so that we can setup the output before
# any logging occurs.
if ENV['VAGRANT_LOG'] && ENV['VAGRANT_LOG'] != ""
  # Require Log4r and define the levels we'll be using
  require 'log4r/config'
  Log4r.define_levels(*Log4r::Log4rConfig::LogLevels)

  level = nil
  begin
    level = Log4r.const_get(ENV['VAGRANT_LOG'].upcase)
  rescue NameError
    # This means that the logging constant wasn't found,
    # which is fine. We just keep `level` as `nil`. But
    # we tell the user.
    level = nil
  end

  # Some constants, such as 'true' resolve to booleans, so the
  # above error checking doesn't catch it. This will check to make
  # sure that the log level is an integer, as Log4r requires.
  level = nil if !level.is_a?(Integer)

  if !level
    # We directly write to stderr here because the VagrantError system
    # is not setup yet.
    $stderr.puts "Invalid VAGRANT_LOG level is set: #{ENV['VAGRANT_LOG']}"
    $stderr.puts ""
    $stderr.puts "Please use one of the standard log levels: debug, info, warn, or error"
    exit 1
  end
  
  logger = Log4r::Logger.new('vagrant')

  LoggingHelper::Log4r.add_outputters(logger)

  logger.level = level
  Log4r::Logger.root.level = level
end

original_log_level = ENV['VAGRANT_LOG']
ENV['VAGRANT_LOG'] = nil

require 'vagrant'

module Vagrant
  def self.plugins_enabled?
    !ENV["VAGRANT_NO_PLUGINS"]
  end
end

if Vagrant.plugins_enabled?
  begin
    Log4r::Logger.new("vagrant::global").info("Loading plugins!")
    Bundler.require(:plugins)
  rescue Exception => e
    raise Vagrant::Errors::PluginLoadError, message: e.to_s
  end
end

require 'vagrant/ui'

module Vagrant
  module UI
    class Colored
      class << self
        @@self_lock = Mutex.new
        @@errored = false

        def errored
          thread = Thread.new do
            @@self_lock.synchronize do
              @@errored
            end
          end
          thread.join
          thread.value
        end

        def errored=(value)
          thread = Thread.new do
            @@self_lock.synchronize do
              @@errored = value
            end
          end.join
        end
      end

      alias :original_format_message :format_message
      def format_message(type, message, **opts)
        original_color = opts[:color]
        original_type = type
        message_buffer = StringIO.new
        lines = message.split("\n")
        lines.each{|message|
          opts[:color] = original_color
          type = original_type
          in_back_trace = false

          if message.include?('================================================================================')
            self.class.errored = true
          elsif message.include?('ERROR')
            opts[:color] = :red
          elsif message.include?('DEBUG')
            opts[:color] = :blue
          elsif message.include?('WARN')
            opts[:color] = :yellow
          elsif message.include?('INFO')
            opts[:color] = :white
          elsif message =~ /.*\.rb:\d+:in \`.*'/
            opts[:color] = :magenta
            in_back_trace = true
          end

          if self.class.errored && !in_back_trace
            type = :error
            opts[:color] = :red
          end

          opts[:bold] = false

          message_buffer.puts original_format_message(type, message, opts)
        }
        message_buffer.string
      end

    end

    class Prefixed

      def colored_ui
        return @colored_ui unless @colored_ui.nil?
        @colored_ui = ::Vagrant::UI::Colored.new
      end

      alias :original_format_message :format_message

      def format_message(type, message, **opts)
        message = original_format_message(type, message, **opts)
        colored_ui.format_message(type, message, **opts)
      end
      
    end
  end
end

ENV['VAGRANT_LOG'] = original_log_level