

Dir.glob(File.expand_path("rake/lib/patch/rake/**/*.rb", $WORKSPACE_SETTINGS[:ecosystem][:paths][:ruby][:home])).each{|patch|
  require patch
}

require 'vagrant/reporter'

Vagrant::Reporter.machine_report

if ENV['USER'] == 'jenkins'
  require 'rake-timer'
end
