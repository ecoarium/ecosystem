
module Plugin
  module MethodMissingIntercept
    module Flexible

      def registry_name
        raise "you must implement this method and return the name/key of the registry to search for plugins!"
      end

      def plugin_action_method_name
        raise "you must implement this method and return the method name on the plugin to call!"
      end

      def signature
        [String, Proc]
      end

      def additional_arguments
        return @additional_arguments unless @additional_arguments.nil?
        @additional_arguments = []
      end
      
      def method_missing(method_symbol, *args, &block)
        debug {
          block_parameter = ''
          block_parameter = ", #{block.inspect}" if block_given?
"
plugin method_missing intercept for registry #{registry_name}:
  #{caller[0]}:#{method_symbol}(#{args.inspect}#{block_parameter})
"
}

        plugin_class = Plugin::Registrar::Registry.lookup(registry_name, method_symbol)

        signature_args_size = signature.size
        signature_args_size -= 1 if signature.last == Proc

        signature_matches_check = Proc.new{|signature_args_size, args|
          signature_matches = false
          index = 0

          until index == signature_args_size  do
             if args[index].is_a? signature[index]
                signature_matches = true
              else
                signature_matches = false
                break
              end
             index += 1
          end

          signature_matches
        }

        example = "
#{method_symbol} #{signature.inspect}
"
        example = %/
#{method_symbol} #{signature[0..signature.size-2].inspect} do
  config some_value

  do_something
  and_maybe_more
end
/ if signature.last == Proc

        raise "You must supply the correct arguments when declaring a #{method_symbol}:#{example}" if args.size != signature_args_size and !signature_matches_check.call(signature, args)
        raise "You must supply a configuration block when declaring a #{method_symbol}:#{example}" if signature.last == Proc and !block_given?

        args += additional_arguments

        plugin = nil
        if block_given?
          debug{"plugin = #{plugin_class}.new(#{args.inspect}, &block)"}
          plugin = plugin_class.new(*args, &block)
        else
          plugin = plugin_class.new(*args)
        end
        plugin.send(plugin_action_method_name.to_s.to_sym)
      end

    end
  end
end