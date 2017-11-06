require 'aws-sdk'
require 'logging-helper'

module CfndslExt
  module CloudFormation
    class Client
      include LoggingHelper::LogToTerminal

      def initialize(region:, access_key_id:, secret_access_key:)
        @client = Aws::CloudFormation::Client.new(
          region: region,
          access_key_id: access_key_id,
          secret_access_key: secret_access_key
        )
      end

      def create_stack(stack_name:, template_body:, tags:)
        debug {"CloudFormation.create_stack(
  stack_name: #{stack_name},
  template_body: #{template_body},
  tags: #{tags.pretty_inspect}
)"}
        @client.create_stack(
          stack_name: stack_name,
          template_body: template_body,
          on_failure: "DO_NOTHING",
          tags: tags
        )
        todo "add code to block until stack deployment is complete", "04/20/2017 02:00 PM"
      end

      def update_stack(stack_name:, template_body:, tags:)
        debug {"CloudFormation.create_stack(
  stack_name: #{stack_name},
  template_body: #{template_body},
  tags: #{tags.pretty_inspect}
)"}
        @client.create_stack(
          stack_name: stack_name,
          template_body: template_body,
          on_failure: "DO_NOTHING",
          tags: tags
        )
        todo "add code to block until stack deployment is complete", "04/20/2017 02:00 PM"
      end

      private

      attr_reader :client

    end
  end
end
