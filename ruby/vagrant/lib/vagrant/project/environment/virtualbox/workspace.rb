require "deep_merge"
require "vagrant/project/environment/base"

module Vagrant
  module Project
    module Environment
      module Virtualbox
        class Workspace < Vagrant::Project::Environment::Base
          register :environment, :workspace, self.inspect

          def configure_provider(machine, &block)
            machine.provider.set_defaults{|vbox|
              #example
              #vbox.name vagrant_machine.name
            }

            block.call()
          end

          def configure_provisioner(machine, &block)
            block.call()
          end
        end
      end
    end
  end
end