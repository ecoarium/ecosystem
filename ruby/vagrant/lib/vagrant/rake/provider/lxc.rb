require "vagrant/rake/provider/common"

module Vagrant
  module Rake
    module Provider
      class LXC
        include Vagrant::Rake::Provider::Common
        
        def initialize
          super
          load_provider_tasks
        end

        def provider_name
          "lxc"
        end

        def load_provider_tasks

        end
      end
    end
  end
end
