
module Smithers
  module ConfigurationItems
    class SCM
      include LoggingHelper::LogToTerminal
      include Attributes::Mixin::Method
      include Plugin::MethodMissingIntercept::Flexible
      extend Plugin::Registrar::Registrant

      register :job_top_level, :scm, self.inspect

      attr_reader :job, :configuration_block

      def initialize(job, &block)
        @job = job
        @configuration_block = block
        additional_arguments.push @job
        additional_arguments.push self
      end
      
      def configure
        job.configuration['scm'] = {} if job.configuration['scm'].nil?
        instance_exec(&configuration_block)
      end

      def registry_name
        :job_scm
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