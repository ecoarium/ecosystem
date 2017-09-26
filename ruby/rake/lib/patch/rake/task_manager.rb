require 'rake/task_manager'

module Rake
  module TaskManager

  	attr_writer :clear_on_define

  	def clear_on_define
  		@clear_on_define = false if @clear_on_define.nil?
  		@clear_on_define
  	end

  	before :define_task do |task_class, *args, &block|
  		if clear_on_define
	  		task_name, arg_names, deps = resolve_args(args)
	  		task_handle = self.lookup(task_name)
	  		task_handle.clear_actions unless task_handle.nil?
	  	end
  	end

	  def remove_task(task_name)
	    @tasks.delete(task_name.to_s)
	  end
	end
end