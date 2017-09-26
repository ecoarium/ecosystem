require 'mixlib/shellout'
require 'logging-helper'
require 'patch/shellout'
require 'patch/shellout-unix'
require 'tempfile'
require 'pp'

module ShellHelper
  module Shell
    include LoggingHelper::LogToTerminal

    INTERNAL_ARGS = [:bash_debug, :bash_exit_on_error]

    def shell_command(command, args={})
      args = {
        :timeout => 36000,
        :live_stdout => $stdout,
        :live_stderr => $stderr
      }.merge(args)

        debug "executing command: [#{command}]\nwith args:\n#{args.pretty_inspect}"
        INTERNAL_ARGS.each{|exclude|
          args.delete(exclude)
        }
        cmd = Mixlib::ShellOut.new(command, args)
        cmd.run_command
        cmd
    end

    def shell_true?(*command)
      shell_command(*command).status.success?
    end

    def shell_command!(command, args={})
      be_quiet = false
      be_quiet = args.delete(:quiet) unless args[:quiet].nil?
      cmd = shell_command(command, args)
      if cmd.error? and be_quiet
        exit
      else
        cmd.error!
      end
      cmd
    end

    def shell_output!(command, args={})
      args = {
        live_stream: nil,
        quiet: false
      }.merge(args)

      result = shell_command!(command, args)
      result.stdout
    end

    def shell_script!(script, args={})
      be_quiet = false
      be_quiet = args.delete(:quiet) unless args[:quiet].nil?
      cmd = shell_script(script, args)
      if cmd.error? and be_quiet
        exit
      else
        cmd.error!
      end
      cmd
    end

    def shell_script(script, args={})
      args = {
        bash_debug: true,
        bash_exit_on_error: true
      }.merge(args)

      script_file = Tempfile.open("shell-helper")
      begin
        script_file.puts("#!/usr/bin/env bash")
        script_file.puts("set -x") if args[:bash_debug]
        script_file.puts("set -e") if args[:bash_exit_on_error]

        script_file.puts(script)
        script_file.close

        FileUtils.chown(args[:user], args[:group], script_file.path)
        #FileUtils.chmod('+x', script_file.path)

        debug{
          debug_shell_script_dir = "/tmp/debug_shell_script"
          FileUtils.mkdir_p debug_shell_script_dir
          debug_shell_script = "#{debug_shell_script_dir}/#{File.basename(script_file.path)}"
          FileUtils.cp(script_file.path, debug_shell_script)
          "shell_script was copied to: #{debug_shell_script}"
        }

        shell_command("bash #{script_file.path}", args)
      ensure
        script_file.close
        script_file.unlink
      end
    end
  end
end
