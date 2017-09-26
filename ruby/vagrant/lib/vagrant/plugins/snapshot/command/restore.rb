require 'optparse'

module VagrantPlugins
  module CommandSnapshot
    module Command  
      class Restore < Vagrant.plugin("2", :command)
        def execute

          options = {}

          opts = OptionParser.new do |opts|
            opts.banner = "Restores a snapshot"
            opts.separator ""
            opts.separator "Usage: vagrant snapshot restore <vmname> -n <snapshot-name> [-h]"
            opts.separator ""
            opts.on("-n", "--name NAME", "Restore named snapshot.") do |name|
              options[:name] = name
            end
          end

          # Parse the options
          argv = parse_options(opts)

          with_target_vms(argv) do |vm|
            if vm.state.id != :not_created
              VirtualBox::Snapshot.new(@env).restore(vm, options[:name])
              vm.action(:up, provision_enabled: false, provision_ignore_sentinel: true)
            else
              vm.env.ui.info I18n.t("vagrant.commands.common.vm_not_created")
            end
          end
          0
        end
      end
    end
  end
end
