
$WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:lib][:tasks][:vagrant] = {} if $WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:lib][:tasks][:vagrant].nil?
$WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:lib][:tasks][:vagrant][:home] = "#{$WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:lib][:tasks][:home]}/vagrant"

$WORKSPACE_SETTINGS[:paths][:project][:workspace][:settings][:rake][:lib][:tasks][:vagrant] = {} if $WORKSPACE_SETTINGS[:paths][:project][:workspace][:settings][:rake][:lib][:tasks][:vagrant].nil?
$WORKSPACE_SETTINGS[:paths][:project][:workspace][:settings][:rake][:lib][:tasks][:vagrant][:home] = "#{$WORKSPACE_SETTINGS[:paths][:project][:workspace][:settings][:rake][:lib][:tasks][:home]}/vagrant"

[
  $WORKSPACE_SETTINGS[:vagrant][:default][:provider],
  $WORKSPACE_SETTINGS[:vagrant][:context]
].each{|path_part|
  ecosystem_task = "#{$WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:lib][:tasks][:vagrant][:home]}/#{path_part}/tasks.rb"
  workspace_task = "#{$WORKSPACE_SETTINGS[:paths][:project][:workspace][:settings][:rake][:lib][:tasks][:vagrant][:home]}/#{path_part}/tasks.rb"

  if !File.exist?(ecosystem_task) and
      !File.exist?(workspace_task)
    raise "the task file does not exist:

#{workspace_task}

"
  end

  if File.exist?(ecosystem_task)
    require ecosystem_task
  end

  if File.exist?(workspace_task)
     require workspace_task
  end
}


require "#{$WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:lib][:tasks][:vagrant][:home]}/tasks.rb"
require "#{$WORKSPACE_SETTINGS[:paths][:project][:workspace][:settings][:rake][:lib][:tasks][:vagrant][:home]}/tasks.rb"
