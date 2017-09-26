require 'chef/application'
require 'chef/application/solo'

Dir.glob(File.expand_path("../patch/*/", File.dirname(__FILE__))).each{|patch_dir|
  Dir.glob(File.expand_path("**/*.rb", patch_dir)).each{|patch|
    require patch
  }
}

