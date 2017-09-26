require 'cucumber'
require 'cucumber/rake/task'
require 'test/load-generator'

Cucumber::Rake::Task.new(:performance_test, "runs the cucumber performance tests") do |t|
  opts = [
    "#{$WORKSPACE_SETTINGS[:paths][:project_paths_acceptance_tests]}/features",
    "--color",
    "--format pretty",
    "--tags @performance",
    "-r #{$WORKSPACE_SETTINGS[:paths][:project_paths_performance_tests]}/lib/performance.rb",
    "-r #{$WORKSPACE_SETTINGS[:paths][:project_paths_acceptance_tests]}/features/steps"
  ]
  t.cucumber_opts = opts.join(' ')
end

desc "e.g. rake run_load_test_on_node[10,3,2,10,'products_page.feature:12'] - times in minutes"
task :run_load_test_on_node, [:rate, :duration, :ramp_time, :max_runners, :scenarios] do |task, args|
  rate = args[:rate].to_f
  duration = args[:duration].to_f
  ramp_time = args[:ramp_time].to_f
  max_runners = args[:max_runners].to_f
  scenarios = args[:scenarios].split(' ')

  Performance::LoadGenerator.run_it(rate, duration, ramp_time, max_runners, scenarios)
end
