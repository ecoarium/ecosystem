require 'digest'
require 'logging-helper'

module Vagrant
  module Project
    module Mixins
      module Artifacts
      	include LoggingHelper::LogToTerminal

      	def resolve_coordinates(artifact_id, group_id, version='LATEST', extension='jar')
          args = {
            artifact_id => /\w/,
            group_id => /[a-zA-Z]*\.[a-zA-Z]*\.[a-zA-Z]*[\.[a-zA-Z]*|""]/,
            version => /[[0-9]*\.[0-9]*\.[0-9]*|LATEST]/,
            extension => /\w{3}/
          }
          validate(args)
          protocol = "https"
          nexus_fqdn = "nexus.#{$WORKSPACE_SETTINGS[:domain_name]}"
          repository_url = File.join(nexus_fqdn, "/nexus/service/local/artifact/maven/redirect?r=releases")
          artifact_url = "#{protocol}://#{repository_url}&g=#{group_id}&a=#{artifact_id}&v=#{version}&e=#{extension}"
        end

        def get_checksum(artifact_uri)
          unless artifact_uri.nil? || artifact_uri.empty?
            if artifact_uri.start_with? 'http'
              checksum = open("#{artifact_uri}.sha1", { ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE }).string
            else
              checksum = Digest::SHA1.file(artifact_uri).hexdigest
            end
            return checksum
          end
          warn "WARN:  Setting checksum to 'nil' since artifact uri is nil!"
          return nil
        end

        def get_file_name(artifact_uri)
          begin
            if artifact_uri.start_with? 'http'
              params = Rack::Utils.parse_query URI(artifact_uri).query
              artifact = params['a']
              extension = params['e']
              return "#{artifact}.#{extension}"
            else
              return File.basename(artifact_uri)
            end
          rescue
            raise %/
              *******************************************************************************
              The Artifact URI is not appropriately set.  Please set artifact_uri to either a
              nexus url or a filepath on the guest machine.

              Current artifact_uri value:  #{artifact_uri}
              Example of valid artifact_uri:  \/var\/chef\/cache\/artifact.zip
              *******************************************************************************
            /
          end
        end

        def validate(args)
          args.each { |param, regex|
            unless param.upcase =~ regex
              raise "#{param} does not meet the required format."
            end
          }
        end
      end
    end
  end
end
