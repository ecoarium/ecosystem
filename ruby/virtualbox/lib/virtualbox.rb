require 'logging-helper'
require 'shell-helper'
require 'pp'

class VirtualBox
  class << self

    @@default_machine_folder = nil
    def default_machine_folder
      return @@default_machine_folder unless @@default_machine_folder.nil?
      @@default_machine_folder = execute("list systemproperties").stdout[/^Default machine folder:\s*(.+?)$/,1]
    end

    @@machines = nil
    def machines
      return @@machines unless @@machines.nil?
      @@machines = execute("list vms").stdout.split("\n").map{|line| line.match(/"(.*)"\s+\{(.*)\}/).captures }.to_h 
    end

    def execute(*command)
      opts = {
        :timeout => 3600,
        :live_stream => nil
      }
      opts = opts.merge(command.pop) if command.last.is_a?(Hash)
      command.insert(0, "VBoxManage")
      shell_command! command.join(' '), opts
    end
  end

  include LoggingHelper::LogToTerminal
  extend ShellHelper::Shell

  @@meta = [
  	{
  		name: :shared_folder_machine_mapping,
  		match: /^SharedFolderNameMachineMapping|SharedFolderPathMachineMapping\d+="/,
  		parser: lambda {|line|
  			@shared_folder_machine_mapping = {
  				by_name: {},
  				by_path: {}
  			} if @shared_folder_machine_mapping.nil?
  			@shared_folder_machine_mapping_tracker = {} if @shared_folder_machine_mapping_tracker.nil?
  			
  			line.scan(/^SharedFolderPathMachineMapping(\d)+="(.+?)"$/){|id,path|
  				if @shared_folder_machine_mapping_tracker[id]
  					@shared_folder_machine_mapping[:by_name][@shared_folder_machine_mapping_tracker[id]] = path
  					@shared_folder_machine_mapping[:by_path][path] = @shared_folder_machine_mapping_tracker[id]
  				else
  					raise "have not seen the shared folder name yet, has something changed with the virtualbox report format?"
  				end
  			}

  			line.scan(/^SharedFolderNameMachineMapping(\d)+="(.+?)"$/){|id,name|
  				if @shared_folder_machine_mapping_tracker[id]
  					raise "duplicate shared folder id #{id} and name #{name}, have seen:\n#{@shared_folder_machine_mapping_tracker.pretty_inspect}"
  				else
  					@shared_folder_machine_mapping_tracker[id] = name
  				end
				}
  		}
  	},
  	{
  		name: :port_forward_table,
  		match: /^Forwarding.+?="/,
  		parser: lambda {|line|
  			@port_forward_table = {} if @port_forward_table.nil?
  			current_nic = self.network_interfaces[-1]

  			line.scan(/^Forwarding.+?="(.+?),.+?,(.*?),(.+?),.*?,(.+?)"$/){|port_name,host_ip,host_port,guest_port|
  				@port_forward_table[guest_port] = [] unless @port_forward_table.has_key?(guest_port)
  				@port_forward_table[guest_port] << {
  					port_name: port_name,
  					host_ip: host_ip,
  					host_port: host_port
  				}
				}
  		}
  	},
  	{
  		name: :network_interfaces,
  		match: /^nic\d+=/,
  		parser: lambda {|line| 
  			@network_interfaces = [] if @network_interfaces.nil?
  			@network_interfaces << line[/^nic(\d+)=".+?"$/,1]
  		}
		},
  	{
  		name: :state,
  		match: /^VMState=/,
  		parser: lambda {|line|
  			@state = line[/^VMState="(.+?)"$/,1].to_sym
  		}
		},
    {
      name: :dir_name,
      match: /^name=/,
      parser: lambda {|line|
        @dir_name = line[/^name="(.+?)"$/,1]
      }
    }
  ]

  @@meta.each{|vm_info|
  	attribute_name = vm_info[:name]
  	class_eval <<-EOS
def #{attribute_name}
	parse_raw if @#{attribute_name}.nil?
	@#{attribute_name}
end
  	EOS
  }

  def initialize(uuid)
    @uuid = uuid
    @parsed = false
  end

  private 

  attr_reader :uuid

  def raw_info
  	return @raw_info unless @raw_info.nil?
  	@raw_info = execute("showvminfo", uuid, "--machinereadable").stdout
  	@raw_info
  end

  def parse_raw
  	return if @parsed

  	raw_info.split("\n").each do |line|
      @@meta.each{|vm_info|
      	instance_exec(line, &vm_info[:parser]) if line.match(vm_info[:match])
      }
    end

  	@parsed = true
  end

  def execute(*command) 
    self.class.execute(*command)
  end
end