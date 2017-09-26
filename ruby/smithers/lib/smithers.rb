
require 'deep_merge'
require 'xmlsimple'
require 'logging-helper'
require 'jenkins_api_client'

require 'plugin/registrar'
require 'plugin/method_missing_intercept/flexible'

require 'attributes/mixin/method'

require 'smithers/command_options'
require 'smithers/environment'
require 'smithers/smithers_file'

[
  "#{$WORKSPACE_SETTINGS[:paths][:project][:jenkins][:home]}/lib",
  File.expand_path('smithers/configuration-items', File.dirname(__FILE__))
].each{|load_path|
  Dir.glob("#{load_path}/**/*.rb"){|config_item|
    require config_item
  }
}