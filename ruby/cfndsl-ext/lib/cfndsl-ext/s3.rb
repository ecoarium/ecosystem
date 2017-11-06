require 'aws-sdk'
require 'logging-helper'

module CfndslExt
  class S3
    include LoggingHelper::LogToTerminal

    def initialize(region:)
      @s3 = Aws::S3::Resource.new(region: region)
    end

    def upload_file(bucket_name, key, file_path)
      obj = @s3.bucket(bucket_name).object(key)
      obj.upload_file(file_path)
    end

  end

end
