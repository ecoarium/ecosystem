require 'json'
require 'shell-helper'

include ShellHelper::Shell
include LoggingHelper::LogToTerminal

$WORKSPACE_SETTINGS[:ecosystem][:paths][:rake] = {} if $WORKSPACE_SETTINGS[:ecosystem][:paths][:rake].nil?

$WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:home] = File.expand_path(File.dirname(__FILE__))

project_rake_lib_dir = "#{$WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:home]}/lib"
$WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:lib] = {} if $WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:lib].nil?
$WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:lib][:home] = project_rake_lib_dir

project_rake_auto_load_dir = "#{project_rake_lib_dir}/auto_load"
$WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:lib][:auto_load] = {} if $WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:lib][:auto_load].nil?
$WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:lib][:auto_load][:home] = project_rake_auto_load_dir

project_rake_classes_dir = "#{project_rake_lib_dir}/classes"
$WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:lib][:classes] = {} if $WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:lib][:classes].nil?
$WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:lib][:classes][:home] = project_rake_classes_dir

project_rake_tasks_dir = "#{project_rake_lib_dir}/tasks"
$WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:lib][:tasks] = {} if $WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:lib][:tasks].nil?
$WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:lib][:tasks][:home] = project_rake_tasks_dir

project_rake_templates_dir = "#{project_rake_lib_dir}/templates"
$WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:lib][:templates] = {} if $WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:lib][:templates].nil?
$WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:lib][:templates][:home] = project_rake_templates_dir

project_rake_resources_dir = "#{project_rake_lib_dir}/resources"
$WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:lib][:resources] = {} if $WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:lib][:resources].nil?
$WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:lib][:resources][:home] = project_rake_resources_dir


Dir.glob("#{$WORKSPACE_SETTINGS[:ecosystem][:paths][:ruby][:home]}/*/rake/**/*.rake").each{|rake_file|
  load rake_file
}

Dir.glob("#{$WORKSPACE_SETTINGS[:paths][:project][:workspace][:settings][:ruby][:home]}/*/rake/**/*.rake").each {|rake_file|
  load rake_file
}

$:.push project_rake_classes_dir

workspace_rake_file = "#{$WORKSPACE_SETTINGS[:paths][:project][:workspace][:settings][:rake][:home]}/default.rb"

load workspace_rake_file if File.exist? workspace_rake_file

Dir.glob("#{project_rake_auto_load_dir}/**/*.rb") {|rake_tasks_file|
  load rake_tasks_file
}

if File.exist? $WORKSPACE_SETTINGS[:paths][:project][:scratch][:rake][:home]
  files = Dir.glob("#{$WORKSPACE_SETTINGS[:paths][:project][:scratch][:rake][:home]}/**/*.rb")
  if $WORKSPACE_SETTINGS[:logging][:show_banner] and !files.empty?
    warn %/
#{divider}

  Loading scratch rake files from:/
    files.each{|scratch_rake_tasks_file|
      load scratch_rake_tasks_file
      warn "    #{scratch_rake_tasks_file}"
    }
    warn "
#{divider}
"
  end
end

task :default do
  puts "Enter 'rake -T' for a list of available tasks with descriptions."
  puts "Visit https://???/display/#{$WORKSPACE_SETTINGS[:project_wiki_name]}/Workspace for more help."
end

desc "Dump Workspace Settings"
task :dump_workspace_settings, :query_opt, :format_opt do |task, args|
  format = :json
  format = args.format_opt.to_sym unless args.format_opt.nil?

  dump = nil
  settings = $WORKSPACE_SETTINGS

  if !args.query_opt.nil? and !args.query_opt.empty?
    eval "settings = $WORKSPACE_SETTINGS[:#{args.query_opt.gsub(/:/, '][:')}]"
  end

  case format
  when :json
    dump = JSON.pretty_generate settings
  when :inspect
    dump = settings.pretty_inspect
  else
    raise "what ever the format argument #{format} is, it is not supported. Use json or inspect."
  end

  puts %/

#{divider}

Workspace Settings Dump:

#{dump}

#{divider}

/
end
