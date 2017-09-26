
require 'berkshelf'

Dir.glob(File.expand_path("*/", File.dirname(__FILE__))).each{|patch_dir|
  Dir.glob(File.expand_path("**/*.rb", patch_dir)).each{|patch|
    require patch
  }
}

if ENV['LOG_LEVEL'].upcase.include?('DEBUG')
  Berkshelf.logger.level = Logger::DEBUG
else
  Berkshelf.logger.level = eval "Logger::#{ENV['LOG_LEVEL'].upcase}" rescue nil
end