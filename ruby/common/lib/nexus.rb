require "nexus_cli"
require "shell-helper"
require 'logging-helper'
require 'fileutils'
require 'xmlsimple'
require 'curl'

class Nexus
  extend LoggingHelper::LogToTerminal
  class << self

    def list_artifact_versions(artifact_id:, group_id:, repository:, extra_coordinates: {})
      username = $WORKSPACE_SETTINGS[:nexus][:credentials][:user_name]
      password = $WORKSPACE_SETTINGS[:nexus][:credentials][:password]
      base_url = $WORKSPACE_SETTINGS[:nexus][:base_url]

      nexus_remote = NexusCli::RemoteFactory.create(
        {
          'url' => base_url,
          'repository' => repository,
          'username' => username,
          'password' => password
        }
      )

      artifact_ext = nil
      if extra_coordinates[:e]
        artifact_ext = extra_coordinates.delete(:e)
      end
      raise "artifact_ext is the only extra_coordinate supported at this time" unless extra_coordinates.empty?
      
      coordinates = "#{group_id}:#{artifact_id}"
      coordinates = "#{coordinates}:#{artifact_ext}" unless artifact_ext.nil?

      results_as_xml_string = nexus_remote.search_for_artifacts(coordinates)
      XmlSimple.xml_in(results_as_xml_string, 'forcearray' => false, 'attrprefix' => true, 'keytosymbol' => true )
    end

    def download_artifact(file_path:, artifact_id:, group_id:, version:, repository:, extra_coordinates: {})
      username = $WORKSPACE_SETTINGS[:nexus][:credentials][:user_name]
      password = $WORKSPACE_SETTINGS[:nexus][:credentials][:password]
      base_url = $WORKSPACE_SETTINGS[:nexus][:base_url]

      nexus_remote = NexusCli::RemoteFactory.create(
        {
          'url' => base_url,
          'repository' => repository,
          'username' => username,
          'password' => password
        }
      )

      artifact_ext = nil
      if extra_coordinates[:e]
        artifact_ext = extra_coordinates.delete(:e)
      end
      raise "artifact_ext is the only extra_coordinate supported at this time" unless extra_coordinates.empty?
      
      coordinates = "#{group_id}:#{artifact_id}"
      coordinates = "#{coordinates}:#{artifact_ext}" unless artifact_ext.nil?
      coordinates = "#{coordinates}:#{version}"

      puts "downloading artifact with coordinates #{coordinates} to #{file_path}"

      file_dir_path = File.dirname(file_path)
      FileUtils.mkdir_p(file_dir_path) unless File.exist? file_dir_path

      artifact_info = nexus_remote.pull_artifact(coordinates, file_dir_path)

      FileUtils.rm_f(file_path) if File.exist?(file_path)
      FileUtils.mv(artifact_info[:file_path], file_path)
    end

    def download_large_artifact(file_path:, artifact_id:, group_id:, version:, repository:, extra_coordinates: {})
      flattened_extra_coordinates = extra_coordinates.join('=', '&')

      url = "#{$WORKSPACE_SETTINGS[:nexus][:rest_end_point]}?r=#{repository}&g=#{group_id}&a=#{artifact_id}&v=#{version}"
      url = "#{url}&#{flattened_extra_coordinates}" unless extra_coordinates.empty?

      Curl.large_download(url, file_path)
    end

    def upload_artifact(group_id:, artifact_id:, artifact_ext:, version:, repository:, artifact_path:)
      raise "Artifact does not exist at #{artifact_path}" unless File.exist?(artifact_path)
      coordinates = "#{group_id}:#{artifact_id}:#{artifact_ext}:#{version}"
      
      Curl.large_upload(
        url: "#{$WORKSPACE_SETTINGS[:nexus][:base_url]}/service/local/artifact/maven/content",
        file_path: artifact_path,
        user_name: $WORKSPACE_SETTINGS[:nexus][:credentials][:user_name],
        password: $WORKSPACE_SETTINGS[:nexus][:credentials][:password],
        form_fields: {
          r: repository,
          hasPom: false,
          e: artifact_ext,
          g: group_id,
          a: artifact_id,
          v: version,
          p: artifact_ext, 
        }
      )

      
      good "uploaded:
#{artifact_path}

to nexus with coordinates:
#{coordinates}
"
    end

  end
end
