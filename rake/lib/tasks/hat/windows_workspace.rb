require 'chef/data_bags/reader'
require 'common/version'
require 'shell-helper'
require 'nexus'
require 'erb'

include LoggingHelper::LogToTerminal
include ShellHelper::Shell

def data_bag_reader
  return @data_bag_reader unless @data_bag_reader.nil?
  @data_bag_reader = Chef::DataBag::Reader.new($WORKSPACE_SETTINGS[:paths][:project][:deploy][:chef][:data][:bags][:home])
end

def build_dir
  "#{$WORKSPACE_SETTINGS[:paths][:project][:home]}/#{$WORKSPACE_SETTINGS[:build_artifact_directory_name]}"
end

def output_dir_path
  "#{build_dir}/windows-zip"
end

def zip_file_path
  "#{build_dir}/#{$WORKSPACE_SETTINGS[:project][:name]}-workspace-setup.7z"
end

def exe_file_path
  "#{build_dir}/#{$WORKSPACE_SETTINGS[:project][:name]}-workspace-setup.exe"
end

def cmd_template_file_name
  'windows-setup.cmd.erb'
end

def bash_template_file_name
  'windows-setup.bash.erb'
end

def config_template_file_name
  'config.txt.erb'
end

def script_file_path(template_file_name)
  "#{output_dir_path}/#{File.basename(template_file_name, '.erb')}"
end

def template_file_path(template_file_name)
  "#{$WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:lib][:templates][:home]}/workspace/#{template_file_name}"
end

desc "build workspace setup"
task :build do
  short_workspace_path = $WORKSPACE_SETTINGS[:paths][:organization][:home][/#{ENV['HOME']}\/(.*)/, 1]
  short_project_paths_home = $WORKSPACE_SETTINGS[:paths][:project][:home][/#{ENV['HOME']}\/(.*)/, 1]
  project_name = $WORKSPACE_SETTINGS[:project][:name]

  branch_name = Common::Version.application_branch
  project_git_repo_url = $WORKSPACE_SETTINGS[:git][:repo][:url]

  mkdir_p output_dir_path unless File.exist?(output_dir_path)

  File.open(script_file_path(bash_template_file_name),"w") {|file|
    file.write ERB.new(File.read(template_file_path(bash_template_file_name))).result(binding)
  }

  File.open(script_file_path(cmd_template_file_name),"w") {|file|
    file.write ERB.new(File.read(template_file_path(cmd_template_file_name))).result(binding)
  }

  File.open(script_file_path(config_template_file_name),"w") {|file|
    file.write ERB.new(File.read(template_file_path(config_template_file_name))).result(binding)
  }

  shell_command! "7z a -t7z #{zip_file_path} ./", cwd: output_dir_path

  create_exe_command = [
    'cat',
    '7zSD.sfx',
    script_file_path(config_template_file_name),
    zip_file_path,
    '>',
    exe_file_path
  ].join(" ")

  shell_command! create_exe_command, cwd: $WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:lib][:resources][:home]

end

desc "publish workspace setup to nexus"
task :publish => [:build] do
  Nexus.upload_artifact(
    group_id:       "#{$WORKSPACE_SETTINGS[:nexus][:base_coordinates][:group_id]}.#{$WORKSPACE_SETTINGS[:project][:name]}.#{Common::Version.application_branch}.workspace_setup",
    artifact_id:    File.basename(exe_file_path, '.*'),
    artifact_ext:   File.extname(exe_file_path).reverse.chop.reverse,
    version:        Common::Version.application_version,
    repository:     $WORKSPACE_SETTINGS[:nexus][:repos][:file],
    artifact_path:  exe_file_path
  )
end
