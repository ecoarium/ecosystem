require 'fileutils'
require "vagrant/rake/provider/common"
require 'vagrant/conventions/provider/virtualbox'
require "virtualbox"
require "terminal-helper/ask"
require 'safe/resource'

module Vagrant
  module Rake
    module Provider
      class VirtualBox
        include Vagrant::Rake::Provider::Common
        include TerminalHelper::AskMixin

        attr_accessor :deployment_time
        def initialize
          super
          @deployment_time = Time.new.getlocal.strftime("%Y%m%d-%H%M%S")
        end

        def provider_name
          "virtualbox"
        end

        def machine_snapshots_file(machine)
          "#{machine_state_dir(machine)}/snapshots"
        end

        def snapshot_machine(machine, snapshot_name, vagrant_opts=[], post_deploy=true)
          if vagrant_opts.is_a?(Array) and !vagrant_opts.empty?
            vagrant_opts = vagrant_opts.join(" ")
          elsif vagrant_opts.is_a?(Array) and vagrant_opts.empty?
            vagrant_opts = ''
          end

          raise "The #{machine} machine has not been created. Run deploy_#{machine} to create it." unless machine_state_exist?(machine)
          raise "A snapshot already exists with the name '#{snapshot_name}'." if has_snapshot?(machine, snapshot_name) and !vagrant_opts.include?('-f')

          vagrant_action(machine, "snapshot take", "-n #{snapshot_name} -d \"#{generate_snapshot_description(machine, post_deploy)}\" #{vagrant_opts}")
        end

        def restore_snapshot(machine, name)
          if machine_state_exist?(machine) and has_snapshot?(machine, name)
            vagrant_action(machine, "snapshot restore", "-n #{name}")
          else
            raise "Could not find snapshot #{name} for the #{machine} machine."
          end
        end

        def delete_snapshot(machine, name)
          if machine_state_exist?(machine) and has_snapshot?(machine, name)
            vagrant_action(machine, "snapshot delete", "-n #{name}")
          else
            raise "Could not find snapshot #{name} for the #{machine} machine."
          end
        end

        def list_snapshots(machine, detail=nil)
          raise "The #{machine} machine has not been created. Run deploy_#{machine} to create it." unless machine_state_exist?(machine)
          vagrant_action(machine, "snapshot status")
        end

        def has_snapshot?(machine, snapshot_name)
          in_list = false
          snapshots(machine).each{ |snapshot, details|
            if details[:name] == snapshot_name
              in_list = true
            end
          }
          in_list
        end

        def current_snapshot(machine)
          snapshots(machine)[:current]
        end

        def snapshots(machine)
          list = {}
          list = JSON.parse(File.read(machine_snapshots_file(machine)), symbolize_names: true) if File.exist?(machine_snapshots_file(machine))
          list
        end

        def current_compared_to_flag?(machine, source_exclutions=[])
          is_current = false

          if machine_state_exist?(machine) and flag_exist?(machine)
            debug {
              "comparing machine #{machine} flag file against source files

  machine flag file:
    #{flag_file(machine)}

  source files:
    #{default_sources.join("\n    ")}
"
            }
            is_current = current?(flag_file(machine), default_sources, source_exclutions)
          end

          return is_current
        end

        def current_compared_to_snapshot?(machine, source_exclutions=[])
          is_current = false

          if machine_state_exist?(machine) and !snapshots(machine).empty? and current_snapshot(machine)[:name] != 'vanilla-base'
            debug {
              "comparing machine #{machine} snapshot file against source files

  machine snapshot file:
    #{machine_snapshots_file(machine)}

  source files:
    #{default_sources.join("\n    ")}
"
            }
            is_current = current?(machine_snapshots_file(machine), default_sources, source_exclutions)
          end

          return is_current
        end

        def generate_snapshot_description(machine, post_deploy=true)
          branch = `git rev-parse --abbrev-ref HEAD`.chomp!
          head = `git rev-parse HEAD`.chomp!
          snapshot_description = {
            :branch => branch,
            :head => head,
            :time => deployment_time,
            :post_deploy => post_deploy
          }.to_json.gsub("\"","\\\"")
        end

        alias_method :common_up_machine, :up_machine

        def up_machine(machine, vagrant_opts=[])
          Safe::Resource.action('up_machine') do
            machine_is_new = !machine_state_exist?(machine)

            if vm_exist?(machine) and machine_is_new
              raise "
the vagrant state is not in sync with the state of virtualbox

the virtualbox machine '#{vbox_vm_name(machine)}' still exists:
  * #{Dir.glob("#{::VirtualBox.default_machine_folder}/#{vbox_vm_name(machine)}/*").join("\n  * ")}

these vagrant state files still exist:
  * #{Dir.glob("machine_state_dir(machine_name)/*").join("\n  * ")}

"
            end

            initial_machine_state = :unknown
            unless machine_is_new
              vm = vm(machine)
              initial_machine_state = vm.state
            end

            common_up_machine(machine, vagrant_opts) unless initial_machine_state == :running

            snapshot_machine(machine, "vanilla-base", [], false) if machine_is_new
          end
        end

        def restore_to_snapshot_instead_of_destroy_machine(machine)
          restore_snapshot(machine, "vanilla-base")
          halt_machine(machine)
        end

        def vm(machine)
          ::VirtualBox.new(machine_id(machine))
        end

        def vm_exist?(machine)
          ::VirtualBox.machines.has_key?(vbox_vm_name(machine))
        end

        def vbox_vm_name(machine)
          Vagrant::Conventions::Provider::VirtualBox.format_machine_name(machine)
        end

        def load_provider_tasks

          add_machine_task(:deploy) {|machine_name, dependencies|
            desc "Bring up all dependencies of #{machine_name} and provision against #{machine_name}"
            multitask "rt_deploy_#{machine_name}".to_sym, [:vagrant_opts] => dependencies do |task, args|
              vagrant_opts = []
              vagrant_opts = args[:vagrant_opts].chomp.split(" ") if args.has_key?(:vagrant_opts)
              up_machine(machine_name, vagrant_opts)
              provision_machine(machine_name, vagrant_opts)
              snapshot_machine(machine_name, deployment_time)
            end

            multitask deploy_task_name => :"rt_deploy_#{machine_name}"
          }

          add_machine_task(:destroy) {|machine_name, dependencies|
            desc "Destroy #{machine_name}"
            multitask "rt_destroy_#{machine_name}".to_sym do
              restore_to_snapshot_instead_of_destroy_machine(machine_name)
            end

            multitask :"rt_destroy" => :"rt_destroy_#{machine_name}"
          }


          add_general_task(:"rt_no_really_destroy") {
            desc "Okay so destroy doesn't really destroy, this one will"
            multitask :"rt_no_really_destroy" => [:"rt_clean_log_dir"]
          }

          add_machine_task(:no_really_destroy_it) {|machine_name, dependencies|
            desc "Okay so destroy doesn't really destroy, this one will destroy #{machine_name}"
            multitask "rt_no_really_destroy_#{machine_name}".to_sym do
              destroy_machine(machine_name)
            end

            multitask :"rt_no_really_destroy" => :"rt_no_really_destroy_#{machine_name}"
          }

          add_machine_task(:take_snapshot) {|machine_name, dependencies|
            desc "Takes a snapshot for the #{machine_name} machine"
            task "rt_take_snapshot_#{machine_name}".to_sym, :snapshot_name, :vagrant_opts  do |task, args|
              raise "the arg snapshot_name is required: rake take_snapshot_machine_name[snapshot_name]" unless args.has_key?(:snapshot_name)

              vagrant_opts = []
              vagrant_opts = args[:vagrant_opts].chomp.split(" ") if args.has_key?(:vagrant_opts)

              snapshot_machine(machine_name, args[:snapshot_name], vagrant_opts, current_compared_to_snapshot?(machine_name))
            end
          }

          add_machine_task(:restore_snapshot) {|machine_name, dependencies|
            desc "Restores the #{machine_name} to specified snapshot"
            task "rt_restore_snapshot_#{machine_name}".to_sym, [:snapshot_name] do |t, args|
              raise "the arg snapshot_name is required: rake restore_snapshot_machine[snapshot_name]" unless args.has_key?(:snapshot_name)
              restore_snapshot(machine_name, args[:snapshot_name])
            end
          }

          add_machine_task(:restore_current_snapshot) {|machine_name, dependencies|
            desc "Restores the #{machine_name} to the current snapshot"
            task "rt_restore_current_snapshot_#{machine_name}".to_sym do
              restore_snapshot(machine_name, current_snapshot(machine_name)[:name])
            end
          }

          add_machine_task(:restore_vanilla_base) {|machine_name, dependencies|
            desc "Restores the #{machine_name} to vanilla-base"
            task "rt_restore_vanilla_base_#{machine_name}".to_sym do
              restore_snapshot(machine_name, 'vanilla-base')
            end
          }

          add_machine_task(:delete_snapshot) {|machine_name, dependencies|
            desc "Deletes the specified snapshot for the #{machine_name} machine"
            task "rt_delete_snapshot_#{machine_name}".to_sym, [:snapshot_name] do |t, args|
              raise "the arg snapshot_name is required: rake delete_snapshot_machine[snapshot_name]" unless args.has_key?(:snapshot_name)
              delete_snapshot(machine_name, args[:snapshot_name])
            end
          }

          add_machine_task(:list_snapshots) {|machine_name, dependencies|
            desc "Lists the snapshots for the #{machine_name} machine"
            task "rt_list_snapshots_#{machine_name}".to_sym do |t, args|
              list_snapshots(machine_name)
            end
          }
        end
      end
    end
  end
end
