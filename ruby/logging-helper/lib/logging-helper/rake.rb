require 'rake'

desc "Use to set the loglevel, options are: #{::LoggingHelper::Util::Config::LOG_LEVELS.keys.collect{|level| level.inspect}.join(", ")}"
task :log_level, :level do |task, args|
  ::LoggingHelper::LogToTerminal::Logger.formatter.config.log_level = args.level.to_sym
  ENV['LOG_LEVEL'] = args.level
end
