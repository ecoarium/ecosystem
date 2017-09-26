require 'pp'
require 'date'
require 'yaml'

class Object
  class << self
    def list_subclasses
      subclasses = [superclass]
      subclasses.concat superclass.list_subclasses unless [Object, Kernel, BasicObject].include? superclass
      subclasses.uniq
    end

    def pretty_class_info
      var_list = list_class_variables.collect{|var_name|
        "#{var_name.inspect} - #{class_variable_get(var_name).pretty_inspect}"
      }

      %/
Class: #{self}
  Inheritance:
     #{list_subclasses.join("\n     ")}

  Included Modules:
     #{list_included_modules.join("\n     ")}

  Extended Modules:
     #{list_extended_modules.join("\n     ")}

  Class Methods:
     #{list_class_methods.join("\n     ")}

  Class Variables:
     #{var_list.join("\n     ")}
/
    end
  end

  def list_instance_variables
    exclude = Object.new.instance_variables
    self.instance_variables.select{|object_variable| !exclude.include?(object_variable) }.sort
  end

  def list_instance_methods
    exclude = Object.new.methods
    exclusive_methods = self.methods.select{|object_method| !exclude.include?(object_method) }.sort
    exclusive_methods
  end

  def pretty_instance_info
    var_list = self.list_instance_variables.collect{|var_name|
      "#{var_name.inspect} - #{instance_variable_get(var_name).pretty_inspect}"
    }

    method_list = self.list_instance_methods.collect {|objects_method|
      method_object = nil
      begin
        method_object = self.method(objects_method)
      rescue
      end

      location = "<location unknown>"
      method_argument_list = []

      unless method_object.nil?
        params = method_object.parameters

        unless params.empty?
          method_argument_list = params.collect{|arg_info|
            argument_display = ""
            case arg_info[0]
            when :req
              argument_display = arg_info[1]
            when :opt
              argument_display = "#{arg_info[1]}=default"
            when :rest
              arg_name = arg_info[1]
              arg_name = 'args' if arg_name.nil?
              argument_display = "*#{arg_name}"
            when :keyreq
              argument_display = arg_info[1].inspect
            when :key
              argument_display = "#{arg_info[1].inspect}=default"
            when :keyrest
              arg_name = arg_info[1]
              arg_name = 'named_args' if arg_name.nil?
              argument_display = "**#{arg_name}"
            when :block
              arg_name = arg_info[1]
              arg_name = 'block' if arg_name.nil?
              argument_display = "&#{arg_info[1]}"
            else
              argument_display = "<unknown-arg-type?#{arg_info.inspect}?unknown-arg-type>"
            end

            argument_display
          }
        end

        location = method_object.source_location.join(":") unless method_object.source_location.nil?
      end

      "#{objects_method}(#{method_argument_list.join(", ")}) -- #{location}"
    }

    %/
#{self.class.pretty_class_info}

Identification:
  id   - #{self.object_id}
  hash - #{self.hash}

Instance Methods:
     #{method_list.join("\n     ")}

Instance Variables:
     #{var_list.join("\n\n     ")}
/
  end

  def before(method_symbol, &block)
    originial_method = self.instance_method(method_symbol)

    define_method(method_symbol) do |*args, &inner_block|
      self.instance_exec(*args, &block)
      originial_method.bind(self).call(*args, &inner_block)
    end
  end

  def after(method_symbol, &block)
    originial_method = self.instance_method(method_symbol)

    define_method(method_symbol) do |*args, &inner_block|
      originial_method.bind(self).call(*args, &inner_block)
      self.instance_exec(*args, &block)
    end
  end

  def deep_to_hash
    yaml_dump = YAML::dump(self)

    converted = StringIO.new
    lines = yaml_dump.split("\n")

    for index in 1..lines.length-1
      line = lines[index]

      if line =~ /\!ruby\/object:/ and !lines[index + 1].nil?
        current_lines_prefix_space = line[/^(\s+)/,1]
        next_lines_prefix_space = lines[index + 1][/^(\s+)/,1]

        if (current_lines_prefix_space.nil? and !next_lines_prefix_space.nil?) or (!current_lines_prefix_space.nil? and !next_lines_prefix_space.nil? and next_lines_prefix_space.length > current_lines_prefix_space.length)
          line.gsub!(/\s+\!ruby\/object:.*/, '')
        end
      end

      line.gsub!(/\!ruby\/object:(.*)/, "'ruby/object:\\1'")
      line.gsub!(/\!ruby\/class '(.*)'/, 'ruby/class:\\1')
      converted.puts line
    end

    yaml = converted.string

    YAML::load(yaml)
  end

  def class_const
    Object.const_get(self.inspect)
  end

  def with(*args, &block)
    instance_exec(*args, &block)
  end

  #example:
  # time_bomb("02/20/2015 02:00 PM", "your message") { optional closure... }
  def time_bomb(datetime, message = 'you wanted to address this by now!', *args, &block)
    timebomb_armed = false
    unless ENV['TIME_BOMB_ARM'].nil?
      raise "Valid values for the env var TIME_BOMB_ARM are 'true' or 'false'; not '#{ENV['TIME_BOMB_ARM']}'" unless %q{true false}.include?(ENV['TIME_BOMB_ARM'])
      timebomb_armed = eval(ENV['TIME_BOMB_ARM'])
    end

    datetime = DateTime.strptime("#{datetime} -05:00", '%m/%d/%Y %I:%M %p %:z') if datetime.is_a?(String)
    datetime = datetime.to_datetime if datetime.is_a?(Date)
    fail %/

      Message:\t\t#{message}
      Detonate on:\t#{datetime}
      Now:\t\t#{DateTime.now}
      Location:\t\t#{caller[0]}
    / if timebomb_armed && datetime < DateTime.now

    instance_exec(*args, &block) if block_given?
  end
end
