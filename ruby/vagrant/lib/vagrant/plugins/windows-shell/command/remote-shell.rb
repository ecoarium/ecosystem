require "vagrant"
require 'logging-helper'
require 'readline'
require 'io/console'
require 'winrm'
require "vagrant/util/safe_exec"

loaded_vagrant_gem_path = Gem::Specification.find_by_name('vagrant').gem_dir

require "#{loaded_vagrant_gem_path}/plugins/communicators/winrm/shell.rb"
require "#{loaded_vagrant_gem_path}/plugins/communicators/winrm/helper.rb"

module VagrantPlugins
  module WindowsShell
    class RemoteShell < Vagrant.plugin(2, :command)
      include LoggingHelper::LogToTerminal
      
      def self.synopsis
        "connects to machine via WinRM"
      end
      
      def execute
        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant win-shell [machine]"
        end

        argv = parse_options(opts)
        return if !argv

        with_target_vms(argv, single_target: true) do |machine|

          pid = fork do

            begin
              winrm_info = ::VagrantPlugins::CommunicatorWinRM::Helper.winrm_info(machine)
              communicator = ::VagrantPlugins::CommunicatorWinRM::WinRMShell.new(winrm_info[:host], winrm_info[:port], machine.config.winrm)
              client = communicator.send(:new_session)

              shell_id = client.open_shell

              command_id = client.run_command(shell_id, 'cmd', "/K prompt []$P$G")

              read_thread = Thread.new do
                client.get_command_output(shell_id, command_id) do |stdout, stderr|
                  puts stdout
                  $stderr.puts stderr
                end
              end
              read_thread.abort_on_exception = true

              while (buf = Readline.readline('', true))
                if buf =~ /^exit/
                  read_thread.exit
                  client.cleanup_command(shell_id, command_id)
                  client.close_shell(shell_id)
                  exit 0
                else
                  client.write_stdin(shell_id, command_id, "#{buf}\r\n")
                end
              end
            rescue Interrupt
              puts 'exiting'
              # ctrl-c
            rescue WinRM::WinRMAuthorizationError
              puts 'Authentication failed, bad user name or password'
              exit 1
            rescue StandardError => e
              puts e.message
              exit 1
            end

            exit
          end
          
          Process.wait(pid) if pid

        end

        0
      end

    end
  end
end
