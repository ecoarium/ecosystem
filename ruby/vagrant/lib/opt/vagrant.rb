if ENV['LOG_LEVEL'].downcase != 'info' and ENV['VAGRANT_LOG'].nil?
  ENV['VAGRANT_LOG'] = ENV['LOG_LEVEL'].downcase
end

require File.expand_path("../vagrant/patches/early/vagrant/logging.rb", File.dirname(__FILE__))

Dir.glob(File.expand_path("../vagrant/patches/early/**/*.rb", File.dirname(__FILE__))).each{|patch|
  require patch
}

$:.push $WORKSPACE_SETTINGS[:paths][:project][:deploy][:vagrant][:lib]

unless ARGV.include?('machines')
  ENV['CREATE_MACHINE_REPORT'] = 'false'
  require 'vagrant/reporter'
  Vagrant::Reporter.machine_report
end

$WORKSPACE_SETTINGS.deep_merge({
	vagrant: {
		report_mode: false
	}
})

require 'git'
require "vagrant/project"
