require 'rake/task'

module Rake
	class Task
		def valid_args?(args)
			missing_args = []
			arg_names.each{|arg_name|
				missing_args << arg_name unless args.has_key?(arg_name)
			}
		end

    def execute(args=nil)
      args ||= EMPTY_TASK_ARGS
      if application.options.dryrun
        application.trace "** Execute (dry run) #{name}"
        return
      end
      application.trace "** Execute #{name}" if application.options.trace
      application.enhance_with_matching_rule(name) if @actions.empty?
      @actions.each do |act|
        case act.arity
        when 1
          act.call(self)
        when 2
          act.call(self, args)
        else
          act.call(self, *(args.to_a))
        end
      end
    end
	end
end
