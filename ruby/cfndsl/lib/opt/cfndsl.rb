
Dir.glob(File.expand_path("../cfndsl/patches/early/**/*.rb", File.dirname(__FILE__))).each{|patch|
  require patch
}

$:.push $WORKSPACE_SETTINGS[:paths][:project][:deploy][:cfndsl][:lib]

require 'cfndsl/project'
