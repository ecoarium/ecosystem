warn "loading early patches for cfndsl, make sure this is required:
#{__FILE__}:#{__LINE__ + 1}"
Dir.glob(File.expand_path("../cfndsl/patches/early/**/*.rb", File.dirname(__FILE__))).each{|patch|
  require patch
}

$:.push $WORKSPACE_SETTINGS[:paths][:project][:deploy][:cfndsl][:lib]

require 'cfndsl/project'
