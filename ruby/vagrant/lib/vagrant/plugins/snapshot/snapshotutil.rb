require 'log4r'
require 'pp'
require 'vagrant'

module VagrantPlugins
  module CommandSnapshot
    module VirtualBox
      class Error < ::Vagrant::Errors::VagrantError
        #status_code(1801)
        error_key(:snapshot)

        def translate_error(opts)
          return nil if !opts[:_key]
          opts[:_key]
        end
      end
      class Snapshot

        attr_reader :logger

        def initialize(env)
          @env=env
          @logger = Log4r::Logger.new(self.class.name.to_s.downcase)
        end

        def status(vm)
          update_snapshots_file(vm)
          unless File.exist?("#{vm.data_dir}/snapshots")
            vm.ui.info " - has no snapshots"
          else
            message = [" - snapshots:"]
            message << JSON.pretty_generate(list_snapshots(vm))
            vm.ui.info message.join("\n")
          end
        end

        def up(vm, options)
          vm.provider.driver.up({"provision.enabled" => false})
          take(vm, options[:name])
          vm.provision() if !options.has_key?("provision.enabled") or options["provision.enabled"]
        end

        def take(vm, name=nil, force=false, description=nil)
          name = Time.new.getlocal.strftime("%Y%m%d-%H%M%S") if   name.nil?
          raise "Cannot take snapshot named current" if name == "current"
          description = "none" unless !description.nil?
          if has_snapshot?(vm,name)
            if force
              delete(vm, name)
            else
              raise VirtualBox::Error.new "Snapshot named '#{name}' for #{vm.name} already exists."
            end
          end
          #Take the snapshot
          vm.ui.info " - taking snapshot named #{name}"
          command_with_progress(vm, "snapshot", vm.provider.driver.uuid, "take", name, "--description", description, "--pause")
          update_snapshots_file(vm)
        end

        def command_with_progress(vm, *args)
          output = ""
          total = ""
          last  = 0
          vm.provider.driver.execute(*args) do |type, data|
            if type == :stdout
              # Keep track of the stdout so that we can get the VM name
              output << data
            elsif type == :stderr
              # Append the data so we can see the full view
              total << data

              # Break up the lines. We can't get the progress until we see an "OK"
              lines = total.split("\n")
              if lines.include?("OK.")
                # The progress of the import will be in the last line. Do a greedy
                # regular expression to find what we're looking for.
                if lines.last =~ /.+(\d{2})%/
                  current = $1.to_i
                  if current > last
                    last = current
                    
                    vm.ui.clear_line
                    vm.ui.report_progress(current, 100, false)
                  end
                end
              end
            end
          end
        end

        def restore(vm, name)
          raise VirtualBox::Error.new "No snapshot named '#{name}' for #{vm.name}." unless has_snapshot?(vm, name)
          
          if vm.provider.driver.read_state == :running
            vm.ui.info " - powering off machine"

            vm.provider.driver.execute("controlvm", vm.provider.driver.uuid, "poweroff", retryable: true)
          end

          vm.ui.info " - roll back machine"

          #Rollback until snapshot
          command_with_progress(vm, "snapshot", vm.provider.driver.uuid, "restore", name)

          update_snapshots_file(vm)
        end

        def delete(vm, name)
          raise VirtualBox::Error.new "No snapshot named '#{name}' for #{vm.name}." unless has_snapshot?(vm, name)

          vm.ui.info " - deleting snapshot named '#{name}'"
          result = vm.provider.driver.execute("snapshot", vm.provider.driver.uuid, "delete", name)
          update_snapshots_file(vm)
        end

        def list_snapshots(vm)
          if File.exist?("#{vm.data_dir}/snapshots")
            full_list = JSON.parse(File.read("#{vm.data_dir}/snapshots"))
          else
            full_list = {}
          end
          full_list
        end

        def has_snapshot?(vm, snapshot_name)
          in_list = false
          list_snapshots(vm).each{ |snapshot, details|
            if details["name"] == snapshot_name
              in_list = true
            end
          }
          in_list
        end

        def update_snapshots_file(vm)
          output = vm.provider.driver.raw("snapshot", vm.provider.driver.uuid, "list", "--machinereadable").stdout
          output.split("\n").each do |line|
            @snapshots = {} if @snapshots.nil?
            @snap_ref = {} if @snap_ref.nil?
            if line.match(/^CurrentSnapshotNode=/)
              current_node = line[/^CurrentSnapshotNode="(.+?)"$/,1]
              @snapshots["current"] = @snapshots[current_node]
            end
            if line.match(/^Snapshot(\w+)(.*?)=/)
              node_name = "SnapshotName#{line[/^(\w+)(.*?)=/,2]}"
              snap_info = line[/^Snapshot(.*?)="(.+?)"$/,2]
              case line[/^Snapshot(\w+)(.*?)=/,1]
              when "Name"
                @snapshots[node_name] = {} if @snapshots[node_name].nil?
                @snapshots[node_name]["name"] = snap_info
              when "Description"
                if snap_info.start_with?("{")
                  @snapshots[node_name]["description"] = JSON.parse(snap_info.gsub("\\",""))
                else
                  @snapshots[node_name]["description"] = snap_info
                end
              when "UUID"
                @snapshots[node_name]["uuid"] = snap_info
              end
            end
          end

          FileUtils.rm_f("#{vm.data_dir}/snapshots")
          unless @snapshots.empty?
            File.open("#{vm.data_dir}/snapshots", 'w') { |file|
              file.write(JSON.pretty_generate @snapshots)
            }
            FileUtils.touch("#{vm.data_dir}/snapshots", :mtime => Time.strptime(@snapshots["current"]["description"]["time"], "%Y%m%d-%H%M%S") )
          end
        end
      end
    end
  end
end