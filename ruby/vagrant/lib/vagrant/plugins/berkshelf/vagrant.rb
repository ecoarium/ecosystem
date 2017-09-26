begin
  require 'vagrant'
rescue LoadError
  raise 'The Vagrant Berkshelf plugin must be run within Vagrant.'
end

require 'fileutils'
require 'json'
require 'tmpdir'

require 'berkshelf'
require 'vagrant/plugins/berkshelf/vagrant/version'
require 'vagrant/plugins/berkshelf/vagrant/errors'

module Berkshelf
  # @author Jamie Winsor <jamie@vialstudios.com>
  module Vagrant
    autoload :StateFileManager,   'vagrant/plugins/berkshelf/vagrant/state-file-manager'
    autoload :Action, 		        'vagrant/plugins/berkshelf/vagrant/action'
    autoload :Config, 		        'vagrant/plugins/berkshelf/vagrant/config'
    autoload :Env, 				        'vagrant/plugins/berkshelf/vagrant/env'
    autoload :EnvHelpers,         'vagrant/plugins/berkshelf/vagrant/env_helpers'

    TESTED_CONSTRAINT = "~> 1.2.0"
  end
end