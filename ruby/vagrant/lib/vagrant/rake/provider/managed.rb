require "vagrant/rake/provider/common"

module Vagrant
  module Rake
    module Provider
      class Managed
        include Vagrant::Rake::Provider::Common
        
        def initialize
          super
          load_provider_tasks
        end

        def provider_name
          "managed"
        end

        def load_provider_tasks

        end
      end
    end
  end
end
