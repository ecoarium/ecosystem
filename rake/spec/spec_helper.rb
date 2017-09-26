ENV['_'] = $0

require 'pp'
require 'deep_merge'
require 'json'

::Dir.glob("#{ENV['ECOSYSTEM_RUBY_HOME']}/*/").each{|slack_gem|
  $:.unshift "#{slack_gem}lib"
}

this_dir = ::File.dirname(__FILE__)
project_rake_lib_dir = ::File.expand_path('../lib', this_dir)
project_rake_classes_dir = ::File.expand_path('classes', project_rake_lib_dir)

$:.push project_rake_classes_dir

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

end
