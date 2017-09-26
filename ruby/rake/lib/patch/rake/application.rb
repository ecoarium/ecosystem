require 'rake/application'

module Rake
  class Application
		def print_rakefile_directory(location)
      puts "rake executing in #{Dir.pwd}" unless
        options.silent or original_dir == location
    end

    alias :original_parse_task_string :parse_task_string
    def parse_task_string(task_entry)
      if task_entry.is_a? String
        original_parse_task_string(task_entry)
      else
        return task_entry[:task_name], task_entry[:task_args]
      end
    end

    def collect_command_line_tasks(args)
      @top_level_tasks = []
      just_the_task_name = nil
      task_entry = nil
      args.each do |arg|
        next if arg.nil? or arg.empty? or arg =~ /^\s+$/

        if arg =~ /^(\w+)=(.*)$/m
          ENV[$1] = $2
        elsif arg =~ /\[.*\]/
          @top_level_tasks << {task_name: arg[/(.*)\[/,1], task_args: arg[/\[(.*)\]/,1].split(',')} 
        elsif arg !~ /\[/ and arg !~ /\]$/ and just_the_task_name.nil?
          @top_level_tasks << {task_name: arg, task_args: []}
        elsif arg =~ /\[$/
          just_the_task_name = arg.gsub(/\[/, '')
          task_entry = {
            task_name: just_the_task_name,
            task_args: []
          }
        elsif arg !~ /\]$/ and just_the_task_name.nil?
          arg = arg.gsub(/,$/, '')
          just_the_task_name, arg_0 = arg.split('[')
          
          task_entry = {
            task_name: just_the_task_name,
            task_args: []
          }

          if !arg_0.nil? and !arg_0.empty? and arg !~ /^\s+$/
            task_entry[:task_args].push arg_0
          end
        elsif arg !~ /\]$/ and !just_the_task_name.nil?
          arg = arg.gsub(/,$/, '')
          task_entry[:task_args].push arg
        elsif arg =~ /\]$/ and !just_the_task_name.nil?
          arg = arg.gsub(/\s{0,}\]$/, '')
          unless arg.nil? or arg.empty?
            task_entry[:task_args].push arg
          end

          @top_level_tasks << task_entry
          
          just_the_task_name = nil
          task_entry = nil
        elsif arg !~ /^-/
          @top_level_tasks << {task_name: arg, task_args: []}
        end
      end
      @top_level_tasks.push(default_task_name) if @top_level_tasks.empty?
    end

  end
end