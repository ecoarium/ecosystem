require "vagrant/rake/provider/common"

module Vagrant
  module Rake
    module Provider
      class AWS
        include Vagrant::Rake::Provider::Common
        
        def initialize
          super
          load_provider_tasks
        end

        def provider_name
          "aws"
        end

        def load_provider_tasks

        end

        def adjust_task_dependencies()

        end
      end
    end
  end
end
