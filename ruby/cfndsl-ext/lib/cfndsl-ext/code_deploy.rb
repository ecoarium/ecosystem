require 'aws-sdk'
require 'logging-helper'

module CfndslExt
  class CodeDeploy
    include LoggingHelper::LogToTerminal

    def initialize(region:, access_key_id:, secret_access_key:)

      @client = Aws::CodeDeploy::Client.new(
        region: region,
        access_key_id: access_key_id,
        secret_access_key: secret_access_key
      )

    end

    def create_deploy(application_name:, deployment_group_name:, deployment_config_name:)
      resp = client.create_deployment({
        application_name: application_name, # required
        deployment_group_name: deployment_group_name,
        revision: {
          revision_type: "S3", # accepts S3, GitHub
          s3_location: {
            bucket: "codedeployecosystembucket",
            key: "SampleApp_Linux.zip",
            bundle_type: "zip", # accepts tar, tgz, zip
            e_tag: "cb00e2bf1dd7a6681216bdbeaf1ebf74"
          }
        },
        deployment_config_name: deployment_config_name,
        description: "Description",
        ignore_application_stop_failures: false,
        target_instances: {
          tag_filters: [
            {
              key: "name",
              value: "dev1",
              type: "KEY_AND_VALUE" # accepts KEY_ONLY, VALUE_ONLY, KEY_AND_VALUE
            }
          ]
        },
        auto_rollback_configuration: {
          enabled: false,
          events: ["DEPLOYMENT_FAILURE"], # accepts DEPLOYMENT_FAILURE, DEPLOYMENT_STOP_ON_ALARM, DEPLOYMENT_STOP_ON_REQUEST
        },
        update_outdated_instances_only: false,
      })

      puts resp
    end

    private

    attr_reader :client

  end
end
