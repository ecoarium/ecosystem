  
module Attributes
  module Mixin
    module Method
      
      module InstanceMethods
        def set_defaults
        end
      end
      
      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
      end
      
      
      module ClassMethods
        def attr_method(*method_symbols)
          method_symbols.each{|method_symbol|
            default_value_assignment = ''
            if method_symbol.is_a?(Hash)
              default_value = method_symbol.values.first
              method_symbol = method_symbol.keys.first
              
              default_value_assignment = %^
                alias :old_set_defaults_#{method_symbol} :set_defaults

                def set_defaults(*args)
                  old_set_defaults_#{method_symbol}(*args)
                  @#{method_symbol} = #{default_value.inspect}
                end
              ^
            end

            method_body = %^

             #{default_value_assignment}

              def #{method_symbol}(arg=nil, &block)
                if !arg.nil? and !block_given?
                  @#{method_symbol} = arg
                end

                if @#{method_symbol}.nil? and block_given?
                  @#{method_symbol} = block.call(arg)
                elsif !@#{method_symbol}.nil? and block_given?
                  @#{method_symbol}.instance_exec(arg, &block)
                end

                if @#{method_symbol}.nil?
                  if block_given? or !arg.nil?
                    raise "something unknown went wrong, a value of nil is the result"
                  end
                end

                return @#{method_symbol}
              end
            ^

            class_eval method_body
          }
        end

      end
    end
  end
end