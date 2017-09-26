
$WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:lib][:tasks][:test] = {} if $WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:lib][:tasks][:test].nil?
$WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:lib][:tasks][:test][:home] = "#{$WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:lib][:tasks][:home]}/test"

$WORKSPACE_SETTINGS[:paths][:project][:workspace][:settings][:rake][:lib][:tasks][:test] = {} if $WORKSPACE_SETTINGS[:paths][:project][:workspace][:settings][:rake][:lib][:tasks][:test].nil?
$WORKSPACE_SETTINGS[:paths][:project][:workspace][:settings][:rake][:lib][:tasks][:test][:home] = "#{$WORKSPACE_SETTINGS[:paths][:project][:workspace][:settings][:rake][:lib][:tasks][:home]}/test"

$WORKSPACE_SETTINGS[:test_types].each{|test_type|
  ecosystem_task = "#{$WORKSPACE_SETTINGS[:ecosystem][:paths][:rake][:lib][:tasks][:test][:home]}/#{test_type}.rb"
  workspace_task = "#{$WORKSPACE_SETTINGS[:paths][:project][:workspace][:settings][:rake][:lib][:tasks][:test][:home]}/#{test_type}.rb"

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