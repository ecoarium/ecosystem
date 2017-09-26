
require 'logging-helper/log-to-terminal'
require 'logging-helper/log4r'
require 'logging-helper/log-to-file'
require 'logging-helper/util/formatter'
require 'logging-helper/util/config'
require 'logging-helper/util/interceptor'

if ENV['_'].end_with?('rake')
  require 'logging-helper/rake'
end