require 'terminal-helper/ask'
require 'chef/data_bags/reader'
require 'common/version'
require 'ssh-executor'
require 'shell-helper'
require 'shellwords'
require 'nexus'
require 'erb'

include ShellHelper::Shell
include TerminalHelper::AskMixin

def data_bag_reader
  return @data_bag_reader unless @data_bag_reader.nil?
  @data_bag_reader = Chef::DataBag::Reader.new($WORKSPACE_SETTINGS[:paths][:project][:deploy][:chef][:data][:bags][:home])
end

def output_dir_path
  "#{$WORKSPACE_SETTINGS[:paths][:project][:home]}/.build"
end

def script_file_path
  "#{output_dir_path}/osx-setup.rb"
end

desc "build workspace setup"
task :build do
  short_workspace_path = $WORKSPACE_SETTINGS[:paths][:organization][:home][/#{ENV['HOME']}\/(.*)/, 1]
  short_project_paths_home = $WORKSPACE_SETTINGS[:paths][:project][:home][/#{ENV['HOME']}\/(.*)/, 1]
  project_name = $WORKSPACE_SETTINGS[:project][:name]
  # project_parent_name = $WORKSPACE_SETTINGS[:project_parent_name]
  branch_name = Common::Version.application_branch
  project_git_repo_url = $WORKSPACE_SETTINGS[:git][:repo][:url]

  template_file_path = "#{$WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:lib][:templates][:home]}/workspace/osx-setup.rb.erb"

  mkdir_p output_dir_path unless File.exist?(output_dir_path)

  File.open(script_file_path,"w") {|file|
    file.write ERB.new(File.read(template_file_path)).result(binding)
  }
  good "built to #{script_file_path}"
end

desc "publish workspace setup to nexus"
task :publish => [:build] do
  Nexus.upload_artifact(
    group_id:       "#{$WORKSPACE_SETTINGS[:nexus][:base_coordinates][:group_id]}.#{$WORKSPACE_SETTINGS[:project][:name]}.#{Common::Version.application_branch}.workspace_setup",
    artifact_id:    File.basename(script_file_path, '.*'),
    artifact_ext:   File.extname(script_file_path).reverse.chop.reverse,
    version:        Common::Version.application_version,
    repository:     $WORKSPACE_SETTINGS[:nexus][:repos][:file],
    artifact_path:  script_file_path
  )
end


desc "correct rights for workspace setup in virtual machine"
task :correct_rights do
  short_project_paths_root = File.basename($WORKSPACE_SETTINGS[:paths][:projects][:root])
  short_company_name = $WORKSPACE_SETTINGS[:company][:name]
  short_organization_name = $WORKSPACE_SETTINGS[:organization][:name]
  short_project_paths_home = $WORKSPACE_SETTINGS[:paths][:project][:home][/#{ENV['HOME']}\/(.*)/, 1]

  ssh = ssh_connection
  script = %^
sudo su <<-'ENDCOMMANDS'
  find /Users/vagrant -exec chown vagrant:vagrant '{}' \;
ENDCOMMANDS
  ^
  ssh.execute_script! script, sudo: false
end

desc "test workspace setup in virtual machine"
task :test, :environment_variables do |t, args|
  env_vars = nil
  env_vars = args[:environment_variables].gsub($WORKSPACE_SETTINGS[:delimiter], "\nexport ") unless args[:environment_variables].nil?
  if env_vars.nil?
    env_vars = ''
  else
    env_vars = "export #{env_vars}"
  end

  username = nil
  password = nil
  credintials_name = 'cp2'

  if File.exist?("#{$WORKSPACE_SETTINGS[:paths][:project][:deploy][:chef][:data][:bags][:home]}/credentials/#{credintials_name}.json" )
    credentials = data_bag_reader.data_bag_item('credentials', credintials_name)

    username = credentials[:username]
    password = credentials[:password]
  else
    username = ask_for_input("please enter your github user name:")
    password = ask_for_sensative_input("please enter your github password:")
  end

  username = Shellwords.escape(username)
  password = Shellwords.escape(password)

  short_project_paths_root = File.basename($WORKSPACE_SETTINGS[:paths][:project_paths_root])
  short_project_parent_name = File.dirname($WORKSPACE_SETTINGS[:project_parent_name])
  short_project_paths_home = $WORKSPACE_SETTINGS[:paths][:project][:home][/#{ENV['HOME']}\/(.*)/, 1]

  time_bomb("05/10/2016 02:00 PM", "set dns server to 10.15.70.11")

  ssh = ssh_connection
  script = %^
    sudo chown vagrant "${HOME}/#{short_project_paths_root}"
    sudo chown vagrant "${HOME}/#{short_project_paths_root}/#{short_project_parent_name}"
    sudo chown vagrant "${HOME}/#{short_project_paths_root}/#{$WORKSPACE_SETTINGS[:project_parent_name]}"
ENDCOMMANDS

    echo "machine #{$WORKSPACE_SETTINGS[:project_git_repo_server_name]} login #{username} password #{password}" > .netrc
    chmod 600 ~/.netrc

    cd "#{short_project_paths_home}"

    export WORKSPACE_SETTING=dev
    export LOG_LEVEL=#{ENV['LOG_LEVEL']}
    #{env_vars}

    source .shell/lib/control/bootstrap.bash
  ^
  exit_code = ssh.execute_script! script, sudo: false

  puts "exit_code -> #{exit_code.inspect}"
end

def ssh_connection
  ssh_ip_address = $WORKSPACE_SETTINGS[:machine_report][:osx_workspace][:ssh_info][:host]
  ssh_user = $WORKSPACE_SETTINGS[:machine_report][:osx_workspace][:ssh_info][:username]
  ssh_private_key = $WORKSPACE_SETTINGS[:machine_report][:osx_workspace][:ssh_info][:private_key_path][0]
  ssh_port = $WORKSPACE_SETTINGS[:machine_report][:osx_workspace][:ssh_info][:port]

  SSHHelper::SSHExecutor.new(ssh_ip_address, ssh_user, ssh_private_key, port: ssh_port)
end
