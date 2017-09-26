require 'optparse'
require 'vagrant'

module VagrantPlugins
  module CommandSnapshot
    module Command
      class Take < Vagrant.plugin("2", :command)
        def execute

          options = {}

          opts = OptionParser.new do |opts|
            opts.banner = "Takes a snapshot"
            opts.separator ""
            opts.separator "Usage: vagrant snapshot take <vmname> -n <snapshot-name> [-h]"
            opts.separator ""
            opts.on("-n", "--name NAME", "Take named snapshot.") do |name|
              options[:name] = name
            end
            opts.separator ""
            opts.on("-f", "--force", "Take named snapshot and overwrite if needed.") do |f|
              options[:force] = f
            end
            opts.separator ""
            opts.on("-d", "--description DESCRIPTION", "Tag the snapshot with a description.") do |desc|
              options[:description] = desc 
            end
          end

          # Parse the options
          argv = parse_options(opts)

          with_target_vms(argv) do |vm|
            if vm.state.id != :not_created
              VirtualBox::Snapshot.new(@env).take(vm, options[:name], options[:force], options[:description])
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

