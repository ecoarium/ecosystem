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

      def delete()
        debug {"Stack.delete()"}

        @stack.delete()

        begin
          wait_for_complete
        rescue Timeout::Error
          raise "Stack.delete failed."
        end
        debug {"Stack.delete finished."}
        puts "The stack status is #{status}!"
      end

      def create(template_body:, tags:)
        debug {"Stack.create(
  template_body: #{template_body},
  tags: #{tags.pretty_inspect}
)"}
        @stack.create(
          template_body: template_body,
          on_failure: "DO_NOTHING",
          tags: tags
        )

        begin
          wait_for_complete
        rescue Timeout::Error
          raise "Stack.create failed."
        end
        debug {"Stack.create finished."}
        puts "The stack status is #{status}!"
      end

      def update(template_body:, tags:)
        debug {"Stack.update(
  template_body: #{template_body},
  tags: #{tags.pretty_inspect}
)"}
        @stack.update(
          template_body: template_body,
          tags: tags
        )
        begin
          wait_for_complete
          Timeout::timeout(3600) do
            puts stack.instance_variable_get(:@data).pretty_inspect
          end
        rescue Timeout::Error
          raise "Stack.update failed."
        end
        debug {"Stack.update finished."}
        puts "The stack status is #{status}!"
      end

      def wait_for_complete
        events_off_set = 0
        Timeout::timeout(3600) do
          until status !~ /IN_PROGRESS/
            events_off_set = show_events(events_off_set)
            sleep(1)
          end
        end
        show_events(events_off_set)
      end

      def show_events(off_set)
        return 0 unless stack.exists?

        events = @stack.events.collect.to_a.reverse

        events[off_set..-1].each{|event|
          puts "--)event_id: #{event.event_id}, logical_resource_id: #{event.logical_resource_id}, physical_resource_id: #{event.physical_resource_id}, resource_status: #{event.resource_status}, resource_status_reason: #{event.resource_status_reason}, resource_type: #{event.resource_type}"
        }

        events.size
      end

      def status
        query_stack = Aws::CloudFormation::Stack.new(
          @stack_name,
          {
            region: region,
            access_key_id: access_key_id,
            secret_access_key: secret_access_key
          }
        )
        if stack.exists?
          query_stack.stack_status
        else
          'NONEXISTENT'
        end
      end

      def outputs
        query_stack = Aws::CloudFormation::Stack.new(
          @stack_name,
          {
            region: region,
            access_key_id: access_key_id,
            secret_access_key: secret_access_key
          }
        )
        query_stack.resource_summaries.collect().to_a
      end

      def exists?
        stack.exists?
      end

      private

      attr_reader :stack, :stack_name, :region, :access_key_id, :secret_access_key

    end
  end
end
