require 'vagrant/project/mixins/configurable'

module Vagrant
  module Project
    module Provider
      module VirtualBox
        module Config
          class Disk
            include Vagrant::Project::Mixins::Configurable
            include LoggingHelper::LogToTerminal

            attr_config :name, :size

            @@disk_count = 1

            def configure_this(vagrant_machine, vbox)
              @@disk_count += 1
              vbox.customize 'pre-boot', ['storagectl', :id, '--name', 'SATA Controller', '--controller', 'IntelAHCI', '--portcount', '30']
              vbox.customize 'pre-boot', ['createhd','--filename', "./#{name}.vdi", '--format', 'VDI', '--size', size * 1024]
              vbox.customize 'pre-boot', ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', @@disk_count, '--device', 0, '--type', 'hdd', '--medium', "./#{name}.vdi"]
            end
          end
        end
      end
    end
  end
end