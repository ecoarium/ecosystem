require 'cucumber/rake/task'
require 'fileutils'

module Test
  class Cucumber
    class << self

      @@tags_arguments = {}
      def tags_arguments
        @@tags_arguments
      end

      def add_tag_argument(task_name, arg)
        tags_arguments[task_name] = [] if tags_arguments[task_name].nil?
        tags_arguments[task_name].push arg
      end

      def flatten_tag_arguments(task_name)
        flatten = StringIO.new
        
        tags_arguments[task_name].each{|tags_argument|
          flatten.puts "--tags #{tags_argument}"
        }

        flatten.string
      end

      @@test_type = nil
      def test_type=(value)
        @@test_type = value
      end
      def test_type
        @@test_type
      end

      @@cucumber_options = []
      def cucumber_options
        return @@cucumber_options unless @@cucumber_options.empty?

        @@cucumber_options = [
          "#{$WORKSPACE_SETTINGS[:paths][:project][:tests][test_type][:home]}",
          "--color",
          "--format pretty",
          "-r #{$WORKSPACE_SETTINGS[:paths][:project][:tests][test_type][:home]}/support",
          "-r #{$WORKSPACE_SETTINGS[:paths][:project][:tests][test_type][:home]}/steps",
        ]
      end

      @@report_folder_path = nil
      def report_folder_path
        return @@report_folder_path unless @@report_folder_path.nil?
        
        @@report_folder_path = "#{$WORKSPACE_SETTINGS[:paths][:project][:tests][test_type][:home]}/.reports"

        FileUtils.mkdir_p @@report_folder_path unless File.exist?(@@report_folder_path)

        @@report_folder_path
      end

      def create_tasks
        tags_arguments.each{|task_name, task_tags_arguments|
          opt_tag_arument = Test::Cucumber.flatten_tag_arguments(task_name)
          ::Cucumber::Rake::Task.new(task_name, "runs cucumber with tag args #{opt_tag_arument}") do |t|
            opts = cucumber_options + [
              "--format html",
              "-o #{report_folder_path}/#{task_name}.html",
              "--format json_pretty",
              "-o #{report_folder_path}/#{task_name}.json",
              opt_tag_arument
            ]

            t.cucumber_opts = opts.join(' ')
          end
        }
      end

    end
  end
end