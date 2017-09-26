require 'optparse'

module VagrantPlugins
  module CommandSnapshot
    module Command
      class Up < Vagrant.plugin("2", :command)
        def execute

          options = {}

          opts = OptionParser.new do |opts|
            options["provision.enabled"] = true
            options["provision.types"] = nil

            opts.banner = "Create machine and take snapshot before provisioning"
            opts.separator ""
            opts.separator "Usage: vagrant snapshot up <vmname> -n <snapshot-name> [--[no-]provision] [-h]"
            opts.separator ""
            opts.on("-n", "--name NAME", "take named snapshot.") do |name|
              options[:name] = name
            end
            opts.on("--[no-]provision", "Enable or disable provisioning") do |p|
              options["provision.enabled"] = p
            end
          end

          # Parse the options
          argv = parse_options(opts)

          with_target_vms(argv) do |vm|
            VirtualBox::Snapshot.new(@env).up(vm, options)
          end
          0
        end
      end
    end
  end
end
