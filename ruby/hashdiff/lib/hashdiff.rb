
loaded_hashdiff_gem_path = Gem::Specification.find_by_name("hashdiff").gem_dir

require "#{loaded_hashdiff_gem_path}/lib/hashdiff.rb"

Dir.glob(File.expand_path("hashdiff/patch/**/*.rb", File.dirname(__FILE__))).each{|patch|
  require patch
}
