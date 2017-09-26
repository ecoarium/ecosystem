require 'rake/application'
require 'fileutils'
require 'json'

module Rake
  class Application

    def report_directory
      return @report_directory unless @report_directory.nil?
      @report_directory = "#{$WORKSPACE_SETTINGS[:paths][:project][:home]}/#{$WORKSPACE_SETTINGS[:build_artifact_directory_name]}/rake-timings"

      FileUtils.mkdir_p report_directory unless File.exist?(report_directory)

      @report_directory
    end

    def report_file_path
      "#{report_directory}/report.json"
    end

    def index_file_path
      "#{report_directory}/index.html"
    end

    def run
      standard_exception_handling do
	      begin
          init
          load_rakefile
          top_level
        ensure 
          create_report
        end
      end
    end

    def create_report
      report = {}

      top_level_tasks.each{|task_string|
        task_name, task_args = parse_task_string(task_string)
        task_obj = self[task_name]
        report = report_on_task(task_obj, report)
      }

      json_report = JSON.pretty_generate report

      File.open(index_file_path,"w") {|file|
        file.write ''
      }
      
      File.open(report_file_path,"w") {|file|
        file.write(json_report)
      }
    end

    def report_on_task(task_obj, report)
      earliest_start_time = task_obj.start

      report[task_obj.name] = {
        start_time: task_obj.start,
        working_duration: task_obj.duration,
        total_duration: task_obj.duration,
        status: task_obj.status,
        dependencies: []
      }

      task_obj.prerequisite_tasks.each{|dep_task|
        sub_report = report_on_task(dep_task, {})
        earliest_start_time = [earliest_start_time, sub_report[dep_task.name][:start_time]].min
        report[task_obj.name][:dependencies].push sub_report
      }

      report[task_obj.name][:start_time] = earliest_start_time

      time_for_prereq_tasks = task_obj.start - earliest_start_time
      report[task_obj.name][:total_duration] = time_for_prereq_tasks + task_obj.duration

      report
    end

  end
end
