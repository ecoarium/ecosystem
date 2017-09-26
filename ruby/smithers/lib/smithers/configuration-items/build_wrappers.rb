
module Smithers
  module ConfigurationItems
    class BuildWrappers
      include LoggingHelper::LogToTerminal
      include Attributes::Mixin::Method
      include Plugin::MethodMissingIntercept::Flexible
      extend Plugin::Registrar::Registrant

      register :job_top_level, :build_wrappers, self.inspect

      attr_reader :job, :configuration_block

      def initialize(job, &block)
        @job = job
        @configuration_block = block
        additional_arguments.push @job
        additional_arguments.push self
      end
      
      def configure
        job.configuration['buildWrappers'] = {} if job.configuration['buildWrappers'].nil?
        instance_exec(&configuration_block)
      end

      def registry_name
        :job_build_wrappers
      end

      def plugin_action_method_name
        :configure
      end

      def signature
        [Proc]
      end

    end
  end
end