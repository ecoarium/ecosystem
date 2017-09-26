require 'winrm'
require 'fileutils'
require 'pathname'
require 'tempfile'
require 'logging-helper'
require 'file_manager'


class WinrmHelper
  class << self
    #here we have connections in a array
    #but in the execute_shell function
    #we will return the result
    #so what happens if we have multiple connections?
    #should we execute all connections?
    #or should we just use one connection?
    @@connections = []

    at_exit {
      #there is no close function in WinRMWebService
      #I think we don't need to close it
      #@@connections.each { |connection| connection.close  }
      puts 'at_exit'
    }
  end
  include LoggingHelper::LogToTerminal

  def initialize(username: username, password: password, host: host, port: port, opts: opts={})
    opts = {
      user: username,
      pass: password,
      host: host,
      port: port,
      basic_auth_only: true,
      no_ssl_peer_verification: false
    }.merge(opts)

    endpoint = "http://#{host}:#{port}/wsman"

    connection = ::WinRM::WinRMWebService.new(endpoint, :plaintext, opts)

    # connection = WinRM::WinRMWebService.new(endpoint, :plaintext, :user => 'vagrant', :pass => 'vagrant', :basic_auth_only => true)
    #connection = WinRM::WinRMWebService.new(endpoint, :plaintext, :user => username, :pass => password, :basic_auth_only => true)
    connection.set_timeout(1800)
    connection.toggle_nori_type_casting(:off)
    
    @@connections << connection
    nil

  end

  def execute_command!(command, sudo=false)
    exit_status = execute_command(command, sudo=false)
    raise "execute_command command [#{command}] failed with exit_status: #{exit_status}" unless exit_status[:exitcode] == 0
    return exit_status
  end

  def execute_command(command, sudo=false)
      @@connections[0].cmd(command) do |stdout, stderr|
          STDOUT.print stdout
          STDERR.print stderr
      end

    
  end

  def upload(from, to)
    #since the File Manager is not in our workspace
    #this function is not able to work
    file_manager = WinRM::FileManager.new(@@connections[0])
    file_manager.upload(from, to)
  end

  def execute_script!(script, opts=nil)
    exit_status = execute_script(script, opts)
    raise "execute_script failed with exit_status: #{exit_status}" if exit_status[:exitcode] != 0
    exit_status
  end

  def execute_script(script, opts=nil)
      @@connections[0].powershell(script) do |stdout, stderr|
          STDOUT.print stdout
          STDERR.print stderr
      end
     

      
  end

  private

  attr_reader :connection

end