require 'terminal-helper/ask'
require 'common/version'
require 'compiler/maven'
require 'fileutils'
require 'nexus'
require 'json'
require 'shell-helper'

include ShellHelper::Shell
include TerminalHelper::AskMixin

task :download_artifact, :version do |t, args|
  version = nil
  version = args['version_opt'] unless args['version_opt'].nil?

  artifact_info = Compiler::Maven.artifact_info
  artifact_id = artifact_info[:artifact_base_file_name]
  group_id = "#{$WORKSPACE_SETTINGS[:nexus][:base_coordinates][:group_id]}.#{Common::Version.application_branch}"
  artifact_ext = artifact_info[:artifact_file_extension]
  repository = $WORKSPACE_SETTINGS[:nexus][:repos][:release]

  if version.nil?
    artifacts = Nexus.list_artifact_versions(
      artifact_id: artifact_id,
      group_id: group_id,
      repository: repository,
      extra_coordinates: {
        e: artifact_ext
      }
    )

    versions = artifacts[:data][:artifact].collect{|artifact_info|
      artifact_info[:version]
    }.sort{|x,y|
      Gem::Version.new(y) <=> Gem::Version.new(x)
    }[0..4]

    version = TerminalHelper::Ask.ask_with_options("Select a version to deploy from the available options:", versions)
  end

  host_artifact_path = File.expand_path("#{$WORKSPACE_SETTINGS[:project][:name].gsub(/-/, '_')}/files/default/dist-file/#{artifact_id}.#{artifact_ext}", $WORKSPACE_SETTINGS[:paths][:project][:deploy][:chef][:cookbook][:home])

  FileUtils.mkdir_p(File.dirname(host_artifact_path)) unless Dir.exist?(File.dirname(host_artifact_path))
  FileUtils.rm_f(host_artifact_path) if File.exist?(host_artifact_path)

  Nexus.download_large_artifact(
    file_path: host_artifact_path,
    artifact_id: artifact_id,
    group_id: group_id,
    version: version,
    repository: repository,
    extra_coordinates: {e: artifact_ext}
  )
end

task :move_artifact => [:package] do
  artifact_info = Compiler::Maven.artifact_info

  host_artifact_path = File.expand_path("#{$WORKSPACE_SETTINGS[:project][:name].gsub(/-/, '_')}/files/default/dist-file/#{artifact_info[:artifact_base_file_name]}.#{artifact_info[:artifact_file_extension]}", $WORKSPACE_SETTINGS[:paths][:project][:deploy][:chef][:cookbook][:home])

  FileUtils.mkdir_p(File.dirname(host_artifact_path)) unless Dir.exist?(File.dirname(host_artifact_path))
  FileUtils.rm_f(host_artifact_path) if File.exist?(host_artifact_path)
  FileUtils.cp(artifact_info[:artifact_file_path], host_artifact_path)
end
