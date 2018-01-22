require 'terminal-helper/ask'
require 'ssh-executor'
require 'virtualbox'

include TerminalHelper::AskMixin

def get_list_of_vms
  result = shell_command! 'VBoxManage list vms', live_stream: nil
  vms = Hash[result.stdout.split("\n").map{|line|
    vm_name = line[/"(.*)"\s+\{.*\}/, 1]
    uuid = line[/".*"\s+\{(.*)\}/, 1]

    [vm_name, uuid]
  }]

  vms
end

def get_listof_vms_on_disk
  Dir.glob("#{VirtualBox.default_machine_folder}/*")
end

def delete_vm(uuid)
  state = VirtualBox.new(uuid).state
  puts "state -- #{state}"
  if state == 'running'
    shell_command! "VBoxManage controlvm #{uuid} poweroff"
  end
  shell_command! "VBoxManage unregistervm #{uuid} --delete"
end

desc "list Virtualbox VMs"
task :vbox_list_all_vms do
  registered_vms = get_list_of_vms
  puts registered_vms.keys.sort.join("\n")

  orphaned_vms = get_listof_vms_on_disk.keep_if{|path| registered_vms[File.basename(path)].nil? }

  unless orphaned_vms.empty?
    puts "
---------
the following are orphaned vms, they are not registered but the files still exist

"

    puts orphaned_vms.join("\n")
  end
end

desc "delete orphaned vms"
task :vbox_delete_orphaned_vms do
  registered_vms = get_list_of_vms
  orphaned_vms = get_listof_vms_on_disk.keep_if{|path| registered_vms[File.basename(path)].nil? }

  orphaned_vms.each{|orphaned_vm_directory_path|
    rm_rf(orphaned_vm_directory_path)
  }
end

desc "list running Virtualbox VMs"
task :vbox_list_running_vms do
  shell_command! 'VBoxManage list runningvms'
end

desc "stop all running Virtualbox VMs"
task :vbox_stop_all_running_vms do
  result = shell_command! 'VBoxManage list runningvms'
  result.stdout.split("\n").each{|line|
    uuid = line[/".*"\s+\{(.*)\}/, 1]
    shell_command! "VBoxManage controlvm #{uuid} poweroff"
  }
end

desc "destroy VirtualBox VM(s)"
task :vbox_destroy_vms, :vms do |t, args|
  vm_name = args[:vms]

  vms = get_list_of_vms
  if vm_name.nil? or vm_name.empty?
    vm_name = ask_with_options("Select a vm to destroy from the available options:", vms.keys)
  end

  delete_vm(vms[vm_name])
end

desc "restart virtualbox"
task :vbox_restart_service do
  puts `sudo '/Library/Application Support/VirtualBox/LaunchDaemons/VirtualBoxStartup.sh' restart`
end
