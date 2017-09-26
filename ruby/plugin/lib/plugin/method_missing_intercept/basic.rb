
module Plugin
  module MethodMissingIntercept
    module Basic

      def registry_name
        raise "you must implement this method and return the name/key of the registry to search for plugins!"
      end

      def plugin_action(plugin_class, *args)
        raise "
you must implement this method!
this is where you would do something like create an instance of the plugin
and take an action with the plugin, for example:

  def plugin_action(plugin_class, *args)
    short_name = args.shift
    plugin = plugin_class.new(short_name: short_name, additional_args: args)

    plugin.configure
  end

"
      end

      def plugin_action(plugin_class, *args. &block)
        raise "
you must implement this method!
this is where you would do something like create an instance of the plugin
and take an action with the plugin, for example:

  def plugin_action(plugin_class, *args, &block)
    short_name = args.shift
    plugin = plugin_class.new(short_name: short_name, additional_args: args, block: block)

    plugin.configure
  end

"
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

        if block_given
          plugin_action(plugin_class, *args, &block)
        else
          plugin_action(plugin_class, *args)
        end
      end

    end
  end
end