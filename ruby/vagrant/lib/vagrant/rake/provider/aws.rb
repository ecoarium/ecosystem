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

        before :rdp_machine do |machine|
          if machine_state_exist?(machine)
            puts "
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

----------------------> #{$WORKSPACE_SETTINGS[:machine_report][machine.to_sym][:winrm_info][:password]} 

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
"
          end
        end

        def load_provider_tasks

        end

        def adjust_task_dependencies()

        end
      end
    end
  end
end
