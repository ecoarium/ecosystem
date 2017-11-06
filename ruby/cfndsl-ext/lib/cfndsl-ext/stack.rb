require 'aws-sdk'
require 'logging-helper'

module CfndslExt
  module CloudFormation
    class Stack
      include LoggingHelper::LogToTerminal

      def initialize(stack_name, region:, access_key_id:, secret_access_key:)
        @stack_name = stack_name
        @region = region
        @access_key_id = access_key_id
        @secret_access_key = secret_access_key
        @stack = Aws::CloudFormation::Stack.new(
          stack_name,
          {
            region: region,
            access_key_id: access_key_id,
            secret_access_key: secret_access_key
          }
        )
      end

      def create(template_body:, tags:)
        debug {"Stack.create(
  stack_name: #{@stack_name},
  template_body: #{template_body},
  tags: #{tags.pretty_inspect}
)"}
        @stack.create(
          template_body: template_body,
          on_failure: "DO_NOTHING",
          tags: tags
        )

        begin
          Timeout::timeout(3600) do
            sleep(1) until status != 'CREATE_IN_PROGRESS'
          end
        rescue Timeout::Error
          raise "Stack.update failed."
        end
        debug {"Stack.update finished."}
        puts "The stack status is #{status}!"
      end

      def update(template_body:, tags:)
        debug {"Stack.update(
  stack_name: #{@stack_name},
  template_body: #{template_body},
  tags: #{tags.pretty_inspect}
)"}
        @stack.update(
          template_body: template_body,
          tags: tags
        )
        begin
          Timeout::timeout(3600) do
            puts stack.instance_variable_get(:@data).pretty_inspect
            sleep(1) until status != 'UPDATE_IN_PROGRESS' && status != 'UPDATE_COMPLETE_CLEANUP_IN_PROGRESS'
          end
        rescue Timeout::Error
          raise "Stack.update failed."
        end
        debug {"Stack.update finished."}
        puts "The stack status is #{status}!"
      end

      def status
        todo "need a better way to check the status.", "04/20/2017 02:00 PM"

        query_stack = Aws::CloudFormation::Stack.new(
          @stack_name,
          {
            region: region,
            access_key_id: access_key_id,
            secret_access_key: secret_access_key
          }
        )
        query_stack.stack_status
      end

      def exists?
        stack.exists?
      end

      private

      attr_reader :stack, :stack_name, :region, :access_key_id, :secret_access_key

    end
  end
end
