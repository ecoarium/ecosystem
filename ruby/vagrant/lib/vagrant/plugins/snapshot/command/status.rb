require 'optparse'

module VagrantPlugins
  module CommandSnapshot
    module Command
      class Status < Vagrant.plugin("2", :command)
        def execute

          options = {}

          opts = OptionParser.new do |opts|
            opts.banner = "List snapshots"
            opts.separator ""
            opts.separator "Usage: vagrant snapshot status <vmname> [<vmname2> <vmname3 ...] [-h]"
            opts.separator ""
          end

          # Parse the options
          argv = parse_options(opts)

          with_target_vms(argv) do |vm|
            if vm.state.id != :not_created
              VirtualBox::Snapshot.new(@env).status(vm)
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
