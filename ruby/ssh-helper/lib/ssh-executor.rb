require 'fileutils'
require 'sshkey'
require 'securerandom'
require 'net/ssh'
require 'net/scp'
require 'pathname'
require 'tempfile'
require 'logging-helper'

module SSHHelper
  class SSHExecutor
    class << self
      @@connections = []

      at_exit {
        @@connections.each { |connection| connection.close  }
      }
    end
    include LoggingHelper::LogToTerminal

    def initialize(host, user, key, ssh_opts)
      ssh_opts = {
        :port                  => 22,
        :keys                  => [],
        :keys_only             => true,
        :user_known_hosts_file => [],
        :paranoid              => false,
        :config                => false,
        :forward_agent         => false
      }.merge(ssh_opts || {})

      unless key.nil?
        if (key.is_a?(String) and key != '')
          ssh_opts[:keys] << key
        elsif (key.is_a?(Array))
          ssh_opts[:keys] << key
        end
      end

      unless ssh_opts[:password].nil?
        raise "the key argument options must include a key or array with at least one ssh private key: 'path/to/key' or ['path/to/key']" if !ssh_opts.has_key?(:keys) and !ssh_opts[:keys].nil? and !ssh_opts[:keys].is_a?(Array) and !ssh_opts[:keys].empty?
      end

      @connection = Net::SSH.start(host, user, ssh_opts)
      @@connections << connection
      nil
    end

    def ssh_execute!(command, sudo=false, shell='/bin/bash -l')
    	exit_status = ssh_execute(command, sudo=false)
    	raise "ssh_execute command [#{command}] failed with exit_status: #{exit_status}" unless exit_status == 0
    	raise unless exit_status == 0
    end

    def ssh_execute(command, sudo=false, shell='/bin/bash -l')
      debug("Execute: #{command} (sudo=#{sudo.inspect})")
      exit_status = nil

      # If we are using `sudo` then we
      # need to wrap the shell in a `sudo` call.
      shell = "sudo -H #{shell}" if sudo

      # Open the channel so we can execute or command
      channel = connection.open_channel do |ch|
        ch.exec(shell) do |ch2, _|
          # Setup the channel callbacks so we can get data and exit status
          ch2.on_data do |ch3, data|
            # Filter out the clear screen command
            data = remove_ansi_escape_codes(data)
            debug data
            if block_given?
              yield :stdout, data
            end
          end

          ch2.on_extended_data do |ch3, type, data|
            # Filter out the clear screen command
            data = remove_ansi_escape_codes(data)
            error data
            if block_given?
              yield :stderr, data
            end
          end

          ch2.on_request("exit-status") do |ch3, data|
            exit_status = data.read_long
            debug "Exit status: #{exit_status}"
          end

          # Set the terminal
          ch2.send_data "export TERM=vt100\n"

          # Output the command
          ch2.send_data "#{command}\n"

          # Remember to exit or this channel will hang open
          ch2.send_data "exit\n"
        end
      end

      # Wait for the channel to complete
      channel.wait

      # Return the final exit status
      return exit_status
    end

    def upload(from, to)
      debug "Uploading: #{from} to #{to}"
      scp = Net::SCP.new(connection)
      scp.upload!(File.open(from, "r"), to)
    end

    def execute_script!(script, opts=nil)
    	exit_status = execute_script(script, opts)
    	raise "execute_script failed with exit_status: #{exit_status}" unless exit_status == 0
      exit_status
    end

    def execute_script(script, opts=nil)
      opts = {
        :command_args => ' ',
        :sudo         => true
      }.merge(opts || {})

      command = "chmod +x /tmp/ssh-executor && /tmp/ssh-executor #{opts[:command_args]}"
      file = Tempfile.new('ssh-executor')
      
      begin
        file.binmode
        file.write(script)
        file.fsync
        file.close

        upload(file.path.to_s, '/tmp/ssh-executor')

        ssh_execute(command, opts[:sudo])
      ensure
        file.close
        file.unlink
      end
    end

    private

    attr_reader :connection

    def remove_ansi_escape_codes(text)
      text = "#{text}"
      # An array of regular expressions which match various kinds
      # of escape sequences. I can't think of a better single regular
      # expression or any faster way to do this.
      matchers = [
        /\e\[\d*[ABCD]/,       # Matches things like \e[4D
        /\e\[(\d*;)?\d*[HF]/,  # Matches \e[1;2H or \e[H
        /\e\[(s|u|2J|K)/,      # Matches \e[s, \e[2J, etc.
        /\e\[=\d*[hl]/,        # Matches \e[=24h
        /\e\[\?[1-9][hl]/,     # Matches \e[?2h
        /\e\[20[hl]/,          # Matches \e[20l]
        /\e[DME78H]/,          # Matches \eD, \eH, etc.
        /\e\[[0-2]?[JK]/,      # Matches \e[0J, \e[K, etc.
      ]

      # Take each matcher and replace it with emptiness.
      matchers.each do |matcher|
        text.gsub!(matcher, "")
      end

      text
    end

  end
end