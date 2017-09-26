require 'thread'

ENV['ORIGIN_THREAD_ID'] = "#{Thread.current.inspect}" unless ENV.has_key?('ORIGIN_THREAD_ID')
ENV['ORIGIN_PROCESS_PID'] = "#{Process.pid}" unless ENV.has_key?('ORIGIN_PROCESS_PID')

log_level = ENV['LOG_LEVEL'] || 'info'

if ARGV.include?('--log-level')
  switch_index = ARGV.index('--log-level')
  ARGV.delete_at(switch_index)
  log_level = ARGV.delete_at(switch_index)
elsif ARGV.include?('--debug')
  switch_index = ARGV.index('--debug')
  ARGV.delete_at(switch_index)
  log_level = 'debug'
end

ENV['LOG_LEVEL'] = log_level

$WORKSPACE_SETTINGS[:logging] = {
  log_level: log_level
}


show_banner = ENV['SHOW_BANNER'] || 'true'

if ARGV.include?('--show-banner')
  switch_index = ARGV.index('--show-banner')
  ARGV.delete_at(switch_index)
  show_banner = ARGV.delete_at(switch_index)
elsif ARGV.include?('-sb')
  switch_index = ARGV.index('-sb')
  ARGV.delete_at(switch_index)
  show_banner = ARGV.delete_at(switch_index)
end

show_banner = eval(show_banner.downcase)

ENV['SHOW_BANNER'] = show_banner.inspect

$WORKSPACE_SETTINGS[:logging][:show_banner] = show_banner

require 'logging-helper'

LoggingHelper::Util::Interceptor.intercept(
	{
 		stdout_log_level: :info,
 		stderr_log_level: :error,
    log_level: log_level.downcase.to_sym
 	}
)

LoggingHelper::LogToTerminal::Logger.logger_debug {
  %/
    original: #{ENV['ORIGIN_PROCESS_PID']} -- #{ENV['ORIGIN_THREAD_ID']}
    current:  #{Process.pid} -- #{Thread.current.inspect}
/
}

if show_banner
  puts %/
------------------------------------------------------------------------------------

      #{File.basename(ENV['_'])} #{ARGV.join(' ')}
      start time:     #{Time.now}

------------------------------------------------------------------------------------
/ if LoggingHelper::LogToTerminal::Logger.formatter.config.log_level == :debug or (ENV['ORIGIN_PROCESS_PID'] == "#{Process.pid}" and ENV['ORIGIN_THREAD_ID'] == "#{Thread.current.inspect}")
end

$WORKSPACE_SETTINGS = {} if $WORKSPACE_SETTINGS.nil?
$WORKSPACE_SETTINGS.deep_merge({start_time: Time.now})

at_exit{
  LoggingHelper::LogToTerminal::Logger.logger_debug {
      %/
    original: #{ENV['ORIGIN_PROCESS_PID']} -- #{ENV['ORIGIN_THREAD_ID']}"
    current:  #{Process.pid} -- #{Thread.current.inspect}
/
  }
  if show_banner
    puts %/
------------------------------------------------------------------------------------

      #{File.basename(ENV['_'])} #{ARGV.join(' ')}
      finish time:     #{Time.now}
      duration:        #{(Time.now - $WORKSPACE_SETTINGS[:start_time]).duration}

------------------------------------------------------------------------------------
/ if LoggingHelper::LogToTerminal::Logger.formatter.config.log_level == :debug or (ENV['ORIGIN_PROCESS_PID'] == "#{Process.pid}" and ENV['ORIGIN_THREAD_ID'] == "#{Thread.current.inspect}")
  end
}
