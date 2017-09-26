require 'pp'

class Module

	def list_included_modules
		ancestor_list = ancestors
		ancestor_list.each{|ancestor|
			next if [Class, Module, Object, Kernel, BasicObject].include? ancestor
			next if ancestor == self

			ancestor_list.concat ancestor.list_included_modules
			ancestor_list.uniq!
		}
		ancestor_list
	end

	def list_extended_modules
		extended_list = included_modules
		extended_list.each{|ancestor|
			next if [Class, Module, Object, Kernel, BasicObject].include? ancestor
			next if ancestor == self

			extended_list.concat ancestor.list_extended_modules
			extended_list.uniq!
		}
		extended_list
  end

  def list_class_variables
    exclude = Object.class_variables
    class_variables.select{|v| !exclude.include?(v) }.sort
  end 

  def list_class_methods
    exclude = Object.methods
    exclusive_methods = methods.select{|m| !exclude.include?(m) }.sort
    exclusive_methods
  end

  def pretty_module_info
    var_list = list_class_variables.collect{|var_name|
      "#{var_name.inspect} - #{class_variable_get(var_name).pretty_inspect}"
    }

    %/
Module: #{self}
  Module Methods:
     #{list_class_methods.join("\n     ")}

  Module Variables:
     #{var_list.join("\n     ")}
/
  end
end