require "log4r"


module Vagrant
  module Project
    module Provider
      class Base

        attr_reader :vagrant_machine, :provider_symbol

        def initialize(vagrant_machine)
          @logger = Log4r::Logger.new(self.class.to_s)
          @vagrant_machine = vagrant_machine
          configuration.provider_symbol provider_symbol
          configuration.vagrant_machine vagrant_machine
        end

        def configuration
        	raise "this method must be implemented in the subclass and return an instance of the provider's configuration class"
        end

        def set_defaults(&block)
          vagrant_machine.vm.box = configuration.box unless configuration.box.nil?
          vagrant_machine.vm.box_url = configuration.box_url unless configuration.box_url.nil?

          if is_configured?
            @logger.warn("set_defaults has been called after provider configuration has already happened")
            provider(&block)
          end
        end

        def configure
        	unless configuration.configured?
            vagrant_machine.vm.box = configuration.box unless configuration.box.nil?
            vagrant_machine.vm.box_url = configuration.box_url unless configuration.box_url.nil?

          	provider{|type|
          		configuration.configure(vagrant_machine,type)
          	}
          end
        end

        def provider(&block)
          provider_config_blocks << block if block_given?
        end

        def provider_overrides(&block)
          override_config_blocks << block if block_given?
        end

        private

        def is_configured?
          !@provider_config_blocks.nil?
        end

        def provider_config_blocks
          raise "looks like the attribute provider_symbol was not set in the class initializer" if provider_symbol.nil?
          unless @provider_config_blocks.nil?
            return @provider_config_blocks
          end
          vagrant_machine.vm.provider(provider_symbol)
          @provider_config_blocks = vagrant_machine.vm.instance_variable_get(:@__providers)[provider_symbol]
          @provider_config_blocks
        end

        def override_config_blocks
          raise "looks like the attribute provider_symbol was not set in the class initializer" if provider_symbol.nil?
          unless @override_config_blocks.nil?
            return @override_config_blocks
          end
          vagrant_machine.vm.provider(provider_symbol)
          @override_config_blocks = vagrant_machine.vm.instance_variable_get(:@__provider_overrides)[provider_symbol]
          @override_config_blocks
        end
      end
    end
  end
end
