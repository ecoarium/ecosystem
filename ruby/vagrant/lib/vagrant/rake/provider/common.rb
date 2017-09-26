require 'rake/dsl_definition'
require 'vagrant/reporter'
require 'logging-helper'
require 'vagrant/shell'
require 'fileutils'
require 'safe/io'
require 'json'

module Vagrant
  module Rake
    module Provider
      module Common
        include Vagrant::Shell
        include LoggingHelper::LogToTerminal
        include ::Rake::DSL

        attr_reader :log_report_at_exit_set, :general_tasks, :machine_tasks
        attr_reader :machine_names, :deployed_machines
        attr_accessor :deploy_task_name, :deploy_from_cache

        def initialize
          @log_report_at_exit_set = false
          @general_tasks = {}
          @machine_tasks = {}
          @machine_names = []
          @deployed_machines = []
          @deploy_task_name = :rt_deploy
          @deploy_from_cache = false
          @add_task_allowed = false
        end

        def provider_name
          raise "this must be implemented by #{self.inspect}!"
        end

        def add_general_task(task_name, &task_block)
          raise "looks like you called load_provider_tasks or called this method outside of load_provider_tasks, this is not supported" unless add_task_allowed?
          general_tasks[task_name] = task_block
        end

        def add_machine_task(task_name, &task_block)
          raise "looks like you called load_provider_tasks or called this method outside of load_provider_tasks, this is not supported" unless add_task_allowed?
          machine_tasks[task_name] = task_block
        end

        def regenerate_tasks
          ::Rake.application.clear_on_define = true
          generate_tasks
          ::Rake.application.clear_on_define = false
        end

        def generate_tasks
          @add_task_allowed = true
          load_tasks
          modify_tasks_to_deploy_from_cache if should_deploy_from_cache?

          general_tasks.each{|id,task_block|
            task_block.call()
          }

          $WORKSPACE_SETTINGS[:machine_report].each do |machine, attributes|
            generate_machine_tasks machine, attributes[:dependencies]
          end
        end

        def machine_id_file(machine)
          File.expand_path("id", machine_state_dir(machine))
        end

        def machine_id(machine)
          IO.read(machine_id_file(machine))
        end

        def machine_state_exist?(machine)
          File.exist?(machine_id_file(machine))
        end

        def machine_state_dir(machine)
          File.expand_path("machines/#{machine}/#{provider_name}", vagrant_state_dir)
        end

        def flag_file(machine)
          File.expand_path("flag", machine_state_dir(machine))
        end

        def flag_exist?(machine)
          File.exist?(flag_file(machine))
        end

        def machine_report_file
          File.expand_path("report.json", vagrant_state_dir)
        end

        def touch_flag_file(machine)
          FileUtils.touch(flag_file(machine))
        end

        def delete_flag_file(machine)
          FileUtils.rm_f(flag_file(machine))
        end

        def delete_machine_report
          FileUtils.rm_f(machine_report_file)
        end

        def log_dir
          if @log_dir.nil? || !File.exist?(@log_dir)
            @log_dir = File.expand_path('logs', vagrant_context_path)
            Safe::IO.action(@log_dir) do
              FileUtils.mkdir_p @log_dir unless File.exist?(@log_dir)
            end
          end
          @log_dir
        end

        def clean_log_dir
          Dir.glob("#{log_dir}/**/*") {|file|
            FileUtils.rm_f file if File.exist? file
          }
        end

        def html_log_report
          @html_log_report = "#{log_dir}/index.html" if @html_log_report.nil?
          @html_log_report
        end

        def add_log_to_report(log_file)
          ensure_log_report_completed
          Safe::IO.action(html_log_report) do
            needs_header = false
            needs_header = true unless File.exist?(html_log_report)
            File.open(html_log_report, "a") { |file|
              if needs_header
                file.write(<<-EOS
                  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
                  <html xmlns ="http://www.w3.org/1999/xhtml">
                    <head>
                      <meta content="text/html;charset=utf-8" http-equiv="Content-Type"/>
                      <title>Vagrant Logs</title>
                    </head>
                      <body>
                  EOS
                )
              end
              file.write("<p><a href='#{File.basename(log_file)}'>#{File.basename(log_file)}</a></p>")
            }
          end
        end

        def ensure_log_report_completed
          return if @log_report_at_exit_set
          at_exit {
            write_html_log_report_footer
          }
          @log_report_at_exit_set = true
        end

        def write_html_log_report_footer
          if @write_html_log_report_footer.nil?
            Safe::IO.action(html_log_report) do
              File.open(html_log_report, "a") { |file|
                file.write(<<-EOS
                  </body>
                  </html>
                  EOS
                )
                @write_html_log_report_footer = true
              }
            end
          end
        end

        def ssh_machine(machine)
          if machine_state_exist?(machine)
            Dir.chdir(vagrant_context_path) do
              exec("vagrant ssh #{machine}")
            end
          else
            raise "The #{machine} machine has not been created. Run deploy_#{machine} to create it."
          end
        end

        def winrm_remote_shell(machine)
          if machine_state_exist?(machine)
            Dir.chdir(vagrant_context_path) do
              exec("vagrant win-shell #{machine}")
            end
          else
            raise "The #{machine} machine has not been created. Run deploy_#{machine} to create it."
          end
        end

        def rdp_machine(machine)
          if machine_state_exist?(machine)

            config_path = Pathname.new(Dir.tmpdir).join("vagrant-rdp-#{Time.now.to_i}-#{rand(10000)}.rdp")
            config_path.open('w+'){|file|
              file.puts "screen mode id:i:1
desktopwidth:i:1600
desktopheight:i:900
use multimon:i:0
session bpp:i:24
full address:s:127.0.0.1:3389
audiomode:i:0
username:s:localhost\\vagrant
disable wallpaper:i:0
disable full window drag:i:0
disable menu anims:i:0
disable themes:i:0
alternate shell:s:
shell working directory:s:
authentication level:i:2
connect to console:i:0
gatewayusagemethod:i:0
disable cursor setting:i:0
allow font smoothing:i:1
allow desktop composition:i:1
redirectprinters:i:0
prompt for credentials on client:i:1


bookmarktype:i:3
use redirection server name:i:0

authoring tool:s:rdmac"
            }

            shell_command! "open '#{config_path.to_s}' &", quiet: true

            shell_command! "osascript #{File.expand_path('apple-script/rdp.apple-script', File.dirname(__FILE__))}"
          else
            raise "The #{machine} machine has not been created. Run deploy_#{machine} to create it."
          end
        end

        def destroy_machine(machine)
          vagrant_action(machine, 'destroy', '-f')
          delete_machine_report
          delete_flag_file(machine)
        end

        def reload_machine(machine, vagrant_opts=[])
          vagrant_opts = [vagrant_opts] if vagrant_opts.is_a?(String)

          vagrant_action(machine, 'reload', "--no-provision #{vagrant_opts.join(" ")}")
          Vagrant::Reporter.regenerate_machine_report
          deployed_machines << machine
        end

        def up_machine(machine, vagrant_opts=[])
          vagrant_opts = [vagrant_opts] if vagrant_opts.is_a?(String)

          vagrant_action(machine, 'up', "--no-provision #{vagrant_opts.join(" ")}")
          Vagrant::Reporter.regenerate_machine_report
          deployed_machines << machine
        end

        def provision_machine(machine, vagrant_opts=[])
          vagrant_opts = [vagrant_opts] if vagrant_opts.is_a?(String)
          up_machine(machine) unless machine_state_exist?(machine)

          vagrant_action(machine, 'provision', vagrant_opts.join(" "))
          touch_flag_file(machine)
          deployed_machines << machine
        end

        def halt_machine(machine)
          vagrant_action(machine, "halt")
        end

        def status_of_all_machines
          raw_vagrant_execution("status")
        end

        def status_machine(machine)
          raw_vagrant_execution("status #{machine}")
        end

        def vagrant_action(machine, vagrant_command, vagrant_switches='')
          log_file = "#{log_dir}/#{machine}.#{vagrant_command.gsub(/ /,'.')}.log"
          add_log_to_report(log_file)

          File.open(log_file, "w") {|io|
            log_level = formatter.config.log_level
            log_level = ENV['VAGRANT_LOG'].to_sym if ENV['VAGRANT_LOG']
            log_level = :debug if vagrant_switches.include?('--debug')

            logger = LoggingHelper::LogToFile.new(io, io, log_level)

            raw_vagrant_execution(
              "#{vagrant_command} #{machine} #{vagrant_switches}",
              logger: logger,
              log_level: log_level
            )
          }
        end

        def load_provider_tasks
          raise "this must be implemented by #{self.inspect}!"
        end

        private

        attr_accessor :add_task_allowed

        def add_task_allowed?
          @add_task_allowed
        end

        def modify_tasks_to_deploy_from_cache
          @deploy_task_name = :deploy_cache
          add_general_task(:machine_report) {
            task :deploy, :version do |t, args|
              version = nil
              if args[:version] == "?"
                version = Vagrant::Rake::Cache::Consumer.ask_version()
              elsif args[:version].nil?
                version = "LATEST"
              else
                version = args[:version]
              end

              info "Deploying #{$WORKSPACE_SETTINGS[:project_name]} version #{version}."

              Vagrant::Rake::Cache::Consumer.pull_cache(version)

              regenerate_tasks

              ::Rake::Task[:deploy_cache].invoke
            end
          }
        end

        def generate_machine_tasks(machine_name, dependencies=[])
          dependencies = dependencies.collect{ |dependency| :"rt_deploy_#{dependency}" } unless dependencies.nil?

          machine_names.push(machine_name)

          machine_tasks.each{|id,task_block|
            task_block.call(machine_name, dependencies)
          }
        end

        def should_deploy_from_cache?
          return deploy_from_cache
        end

        def load_tasks
          load_default_tasks
          load_provider_tasks
        end

        def load_default_tasks

          add_general_task(:clean_log_dir) {
            task :"rt_clean_log_dir" do
              clean_log_dir
            end
          }

          add_general_task(:deploy) {
            desc "Deploy all machines in dependency order"
            multitask deploy_task_name => [:"rt_clean_log_dir"]
          }

          add_general_task(:destroy) {
            desc "Destroy all machine_names in reverse dependency order"
            task :"rt_destroy" => [:"rt_clean_log_dir"]
          }

          add_general_task(:status) {
            desc "Shows statuses of all machines."
            task :"rt_status" do
              status_of_all_machines
            end
          }

          add_general_task(:up) {
            desc "Starts all machines."
            task :"rt_up"
          }

          add_general_task(:down) {
            desc "Shutdown all machines."
            multitask :"rt_down"
          }

          add_machine_task(:down_machine) {|machine_name, dependencies|
            desc "Shutdown #{machine_name} machine"
            task "rt_down_#{machine_name}".to_sym do |t, args|
              halt_machine(machine_name)
            end

            multitask :"rt_down" => :"rt_down_#{machine_name}"
          }

          add_machine_task(:up) {|machine_name, dependencies|
            desc "vagrant up #{machine_name}"
            task "rt_up_#{machine_name}".to_sym, :vagrant_opts do |task, args|
              vagrant_opts = []
              vagrant_opts = args.vagrant_opts.chomp.split(" ") if args.has_key?(:vagrant_opts)
              up_machine(machine_name, vagrant_opts)
            end

            task :"rt_up" => :"rt_up_#{machine_name}"
          }

          add_machine_task(:deploy) {|machine_name, dependencies|
            desc "Bring up all dependencies of #{machine_name} and provision against #{machine_name}"
            multitask "rt_deploy_#{machine_name}".to_sym, [:vagrant_opts] => dependencies do |task, args|
              vagrant_opts = []
              vagrant_opts = args.vagrant_opts.chomp.split(" ") if args.has_key?(:vagrant_opts)
              provision_machine(machine_name, vagrant_opts)
            end

            multitask deploy_task_name => :"rt_deploy_#{machine_name}"
          }

          add_machine_task(:destroy) {|machine_name, dependencies|
            desc "Destroy #{machine_name}"
            multitask "rt_destroy_#{machine_name}".to_sym do
              destroy_machine(machine_name)
            end

            multitask :rt_destroy => :"rt_destroy_#{machine_name}"
          }

          add_machine_task(:status) {|machine_name, dependencies|
            desc "Show status of #{machine_name}"
            task "rt_status_#{machine_name}".to_sym do
              status_machine(machine_name)
            end
          }

          add_machine_task(:reload) {|machine_name, dependencies|
            desc "vagrant reload #{machine_name}"
            task "rt_reload_#{machine_name}".to_sym, :vagrant_opts do |task, args|
              vagrant_opts = []
              vagrant_opts = args[:vagrant_opts].chomp.split(" ") if args.has_key?(:vagrant_opts)
              reload_machine(machine_name, vagrant_opts)
            end

            if $WORKSPACE_SETTINGS[:machine_report].length == 1
              desc "vagrant reload #{machine_name}"
              task :"rt_reload" do
                reload_machine(machine_name)
              end
            end
          }

          add_machine_task(:ssh) {|machine_name, dependencies|
            if $WORKSPACE_SETTINGS[:machine_report][machine_name][:guest] != 'windows'
              desc "ssh to #{machine_name}"
              task "ssh_#{machine_name}".to_sym do
                ssh_machine(machine_name)
              end

              if $WORKSPACE_SETTINGS[:machine_report].length == 1
                desc "ssh to #{machine_name}"
                task :ssh do
                  ssh_machine(machine_name)
                end
              end
            elsif $WORKSPACE_SETTINGS[:machine_report][machine_name][:guest] == 'windows'
              desc "remote shell to #{machine_name}"
              task "remote_#{machine_name}".to_sym do
                winrm_remote_shell(machine_name)
              end

              if $WORKSPACE_SETTINGS[:machine_report].length == 1
                desc "remote shell to #{machine_name}"
                task :remote do
                  winrm_remote_shell(machine_name)
                end
              end
            end
          }

          add_machine_task(:rdp) {|machine_name, dependencies|
            if $WORKSPACE_SETTINGS[:machine_report][machine_name][:guest] == 'windows'
              desc "rdp to #{machine_name}"
              task "rdp_#{machine_name}".to_sym do
                rdp_machine(machine_name)
              end

              if $WORKSPACE_SETTINGS[:machine_report].length == 1
                desc "rdp to #{machine_name}"
                task :rdp do
                  rdp_machine(machine_name)
                end
              end
            end
          }
        end
      end
    end
  end
end
