ENV['_'] = $0

$stdout.sync = true
$stderr.sync = true

require 'pp'
require 'deep_merge'

Dir.glob("#{ENV['ECOSYSTEM_PATHS_RUBY_HOME']}/*/").each{|slack_gem|
  $:.unshift "#{slack_gem}lib"
}

Dir.glob("#{ENV['PATHS_PROJECT_WORKSPACE_SETTINGS_RUBY_HOME']}/*/").each {|slack_gem|
  $:.unshift "#{slack_gem}lib"
}

Dir.glob(File.expand_path("common/lib/patch/ruby/**/*.rb", ENV['ECOSYSTEM_PATHS_RUBY_HOME'])).each{|patch|
  require patch
}

require 'opt/workspace-settings'
require 'opt/logging'

$:.unshift $WORKSPACE_SETTINGS[:paths][:project][:scratch][:lib][:home]

scratch_opt_file = File.expand_path('opt/scratch.rb', $WORKSPACE_SETTINGS[:paths][:project][:scratch][:lib][:home])
if File.exist? scratch_opt_file
  LoggingHelper::LogToTerminal::Logger.warn %/
#{LoggingHelper::LogToTerminal::Logger.divider}

  Loading scratch opt file from:
    #{scratch_opt_file}/ if $WORKSPACE_SETTINGS[:logging][:show_banner]
  require scratch_opt_file
  LoggingHelper::LogToTerminal::Logger.warn "\n#{LoggingHelper::LogToTerminal::Logger.divider}\n" if $WORKSPACE_SETTINGS[:logging][:show_banner]
end

require 'opt/berkshelf'

if ENV['_'].end_with?('rake')
  require 'opt/rake'
end

if ENV['_'].end_with?('cucumber')
  require 'opt/cucumber'
end

if ENV['_'].end_with?('chef-solo')
  require 'opt/chef'
end

if ENV['_'].end_with?('vagrant')
  require 'opt/vagrant'
end

if ENV['_'].end_with?('cfndsl')
  require 'opt/cfndsl'
end

if ENV['_'].end_with?('pry') or ENV['_'].end_with?('irb')
  require 'vagrant/reporter'

  Vagrant::Reporter.machine_report
end
