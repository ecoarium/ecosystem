
require 'logging-helper'

module Vagrant
  module Project
    module Mixins
      module Configurable
        module DSL

          include LoggingHelper::LogToTerminal

          def validators
            @validators = {} if @validators.nil?
            @validators
          end

          def excluded_configurations
            @excluded_configurations = [:@is_configured] if @excluded_configurations.nil?
            @excluded_configurations
          end

          def attr_config(*args, &validate_block)
            configurable_item_class = nil
            attribute_is_array = false

            opts = {}
            if args.last.is_a?(Hash)
              opts = args.pop
              configurable_item_class = opts.delete(:class)
              attribute_is_array = !opts.delete(:is_array) == false
            end

            if !opts.empty? or args.empty? or args.any?{|arg| !arg.is_a?(Symbol) or arg !~ /^\w+$/ }
              raise %/

                attr_config can be called with multiple arguments.
                at least one argument must be a symbol, the name of the config attribute(i.e. method).
                optionally the last argument may be a hash of the following format:

                  {
                    class: Full::Path::To::Class,
                    is_array: true
                  }

                the key value pairs are independent from each other.
                finally a closure may optionally be supplied as a validation mechanism during configuration.

                a limited set of examples:

                attr_config :url

                attr_config :ip_address, :port

                attr_config :load_balance_list, is_array: true

                attr_config :artifact_coordinates do
                  if artifact_coordinates.split(':').size != 4
                    {
                      is_valid: false, # [true | false]
                      failure_message: 'artifact_coordinates must if the following format: group_id:artifact_id:version:ext'
                    }
                  else
                    {is_valid: true}
                  end
                end
              /
            end

            args.each{|method_symbol|
              set_instance_variable_of_class_without_args = ""
              new_configurable_item = ""
              if configurable_item_class.nil?
                new_configurable_item = "args.last"
              else
                new_configurable_item = "#{configurable_item_class}.new(*args)"
                if attribute_is_array
                  set_instance_variable_of_class_without_args = <<-EOS
                    if args.empty?
                      @#{method_symbol} = [] if @#{method_symbol}.nil?
                      @#{method_symbol} << #{configurable_item_class}.new
                    end
                  EOS
                else
                  set_instance_variable_of_class_without_args = <<-EOS
                    if args.empty? and @#{method_symbol}.nil?
                      @#{method_symbol} = #{configurable_item_class}.new
                    end
                  EOS
                end
              end

              set_instance_variable = ""
              exec_instance_eval = ""
              if attribute_is_array
                exec_instance_eval = <<-EOS
                  @#{method_symbol}.last.instance_exec(*args, &block)
                EOS
                set_instance_variable = <<-EOS
                  @#{method_symbol} = [] if @#{method_symbol}.nil?
                  @#{method_symbol} << #{new_configurable_item}
                EOS
              else
                exec_instance_eval = <<-EOS
                  @#{method_symbol}.instance_exec(*args, &block)
                EOS
                set_instance_variable = "@#{method_symbol} = #{new_configurable_item}"
              end



              method_body = <<-EOS
                def #{method_symbol}(*args, &block)
                  if !args.empty? and !block_given?
                    #{set_instance_variable}
                  end

                  #{set_instance_variable_of_class_without_args}

                  if @#{method_symbol}.nil? and block_given?
                    @#{method_symbol} = block.call(*args)
                  elsif !@#{method_symbol}.nil? and block_given?
                    #{exec_instance_eval}
                  end

                  if @#{method_symbol}.nil?
                    if block_given? or !args.empty?
                      raise "something unknown went wrong, a value of nil is the result"
                    end
                  end

                  return @#{method_symbol}
                end
              EOS

              class_eval method_body
              validators[method_symbol] = validate_block if block_given?
            }
          end
        end

        def validate
          failures = []
          result = validate_this
          failures << result[:failure_message] unless result[:is_valid]

          configurable_variables.each{|var_name|
            var = instance_variable_get(var_name.to_s)
            if var.respond_to?(:validate)
              result = var.validate
              failures << result[:failure_message] unless result[:is_valid]
            elsif var.is_a?(Array)
              var.each{|item|
                if item.respond_to?(:validate)
                  result = item.validate
                  failures << result[:failure_message] unless result[:is_valid]
                end
              }
            end
          }

          if failures.empty?
            return {is_valid: true}
          else
            return {is_valid: false, failure_message: failures.join("\n")}
          end
        end

        def configure(*args)
          return if configured?
          validate_this!
          configure_this(*args)
          configurable_variables.each{|var_name|
            var = instance_variable_get(var_name.to_s)
            if var.respond_to?(:configure)
              var.configure(*args)
            elsif var.is_a?(Array)
              var.each{|item|
                item.configure(*args) if item.respond_to?(:configure)
              }
            end
          }
          is_configured = true
        end

        def self.included(receiver)
          receiver.extend DSL
        end
        
        def configured?
          is_configured == true
        end

        protected

        def configure_this(*args)
          raise %/

          A configurable must implement this method.
          This is the method that actually takes configuration actions for this class.
          This method is called before iterating over all children configurables.

          /
        end

        def configurable_variables
          vars = instance_variables
          self.class.excluded_configurations.each{|exclude|
            vars.delete exclude
          }
          vars
        end

        private

        attr_accessor :is_configured

        def validate_this!
          result = validate_this
          raise result[:failure_message] unless result[:is_valid]
        end

        def validate_this
          results = self.class.validators.collect{|configuration,validate_block| validate_wrapper(validate_block)}

          failures = results.collect{|result|
            result[:failure_message] unless result[:is_valid]
          }
          failures.compact!

          if failures.empty?
            return {is_valid: true}
          else
            return {is_valid: false, failure_message: failures.join("\n")}
          end
        end

        def validate_wrapper(block)
          result = instance_exec &block
          if !result.is_a?(Hash) and result[:is_valid].nil? and result[:failure_message].nil?
            raise %/
            all configurations require a validation closure that returns a hash of the following format:

            this is an example of a successful validation
            {
              is_valid: true
            }

            this is an example of a failing validation
            {
              is_valid: false,
              failure_message: 'this is my best as to what is wrong...'
            }
            /
          end
          return result
        end
      end
    end
  end
end