require 'ssh-executor'

desc "correct rights for workspace setup in virtual machine"
task :correct_rights do
  ssh = ssh_connection
  script = %^
sudo su <<-'ENDCOMMANDS'
  find /home/vagrant -exec chown vagrant:vagrant '{}' \;
ENDCOMMANDS
  ^
  ssh.execute_script! script, sudo: false
end

def ssh_connection
  ssh_ip_address = $WORKSPACE_SETTINGS[:machine_report][:linux_workspace][:ssh_info][:host]
  ssh_user = $WORKSPACE_SETTINGS[:machine_report][:linux_workspace][:ssh_info][:username]
  ssh_private_key = $WORKSPACE_SETTINGS[:machine_report][:linux_workspace][:ssh_info][:private_key_path][0]
  ssh_port = $WORKSPACE_SETTINGS[:machine_report][:linux_workspace][:ssh_info][:port]

  SSHHelper::SSHExecutor.new(ssh_ip_address, ssh_user, ssh_private_key, port: ssh_port)
end
