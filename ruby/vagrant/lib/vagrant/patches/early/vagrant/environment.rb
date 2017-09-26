
require 'vagrant/environment'

module Vagrant
  class Environment

  	alias :original_setup_home_path :setup_home_path
  	def setup_home_path
  		original_setup_home_path
  		
  		Dir.glob(File.expand_path("vagrant/lib/vagrant/plugins/*/plugin.rb", $WORKSPACE_SETTINGS[:ecosystem][:paths][:ruby][:home])).each{|plugin|
			  require plugin
			}

			Dir.glob(File.expand_path("vagrant/lib/vagrant/plugins/patches/**/*.rb", $WORKSPACE_SETTINGS[:ecosystem][:paths][:ruby][:home])).each{|plugin_patch|
			  require plugin_patch
			}
  	end

  end
end
