
$WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:lib][:tasks][:hat] = {} if $WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:lib][:tasks][:hat].nil?
$WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:lib][:tasks][:hat][:home] = "#{$WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:lib][:tasks][:home]}/hat"

$WORKSPACE_SETTINGS[:paths][:project][:workspace][:settings][:rake][:lib][:tasks][:hat] = {} if $WORKSPACE_SETTINGS[:paths][:project][:workspace][:settings][:rake][:lib][:tasks][:hat].nil?
$WORKSPACE_SETTINGS[:paths][:project][:workspace][:settings][:rake][:lib][:tasks][:hat][:home] = "#{$WORKSPACE_SETTINGS[:paths][:project][:workspace][:settings][:rake][:lib][:tasks][:home]}/hat"

$WORKSPACE_SETTINGS[:hats].each{|hat|
  ecosystem_task = "#{$WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:lib][:tasks][:hat][:home]}/#{hat}.rb"
  workspace_task = "#{$WORKSPACE_SETTINGS[:paths][:project][:workspace][:settings][:rake][:lib][:tasks][:hat][:home]}/#{hat}.rb"

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