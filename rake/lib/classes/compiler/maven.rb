require 'shell-helper'
require 'logging-helper'
require 'fileutils'
require 'zip'
require 'common/version'
require 'facets/module/cattr'

module Compiler
  class Maven
    
    extend ShellHelper::Shell
    extend LoggingHelper::LogToTerminal

    class << self

      def run_command!(command, path=$WORKSPACE_SETTINGS[:paths][:project][:production][:home])
        shell_command! "mvn #{command}", cwd: path
      end

      def insert_version_into_artifact(artifact_path:, artifact_name: $WORKSPACE_SETTINGS[:nexus][:base_coordinates][:artifact_id], artifact_ext: 'jar', version: Common::Version.application_version, commit_hash: Common::Version.application_commit_hash)
        output_dir = File.expand_path(File.dirname(artifact_path))
        output_file_path = "#{output_dir}/#{artifact_name}-#{version}.#{artifact_ext}"
        
        File.open("#{output_dir}/MANIFEST.MF", "w"){|manifest_file|
          manifest_file_content = "Implementation-Title: #{artifact_name}
Implementation-Version: #{version}
Implementation-CommitHash: #{commit_hash}
"
          manifest_file.write manifest_file_content
        }

        FileUtils.cp_f(artifact_path, output_file_path)
        shell_command! "jar vfum #{output_file_path} #{output_dir}/MANIFEST.MF", cwd: artifact_info[:output_dir]
      end

      def position_artifact(artifact_path)
        FileUtils.cp_f(artifact_path, artifact_info[:artifact_file_path])
      end

      @@artifact_info = nil
      def artifact_info(overrides={})
        debug {"artifact_info(#{overrides.inspect})\n@@artifact_info:\n#{@@artifact_info.pretty_inspect}"}
        return @@artifact_info if !@@artifact_info.nil? and overrides.empty?
        if @@artifact_info.nil?
          @@artifact_info = {
            output_dir: "#{$WORKSPACE_SETTINGS[:paths][:project][:production][:home]}/#{$WORKSPACE_SETTINGS[:build_artifact_directory_name]}",
            artifact_base_file_name: $WORKSPACE_SETTINGS[:nexus][:base_coordinates][:artifact_id],
            artifact_file_extension: "zip",
            artifact_version: Common::Version.application_version,
            artifact_hash: Common::Version.application_commit_hash
          }
          debug {"artifact_info was nil, now @@artifact_info is:\n#{@@artifact_info.pretty_inspect}"}
        end

        unless overrides.empty?
          @@artifact_info = @@artifact_info.merge(overrides)
          debug {"overrides was not nil, now @@artifact_info is:\n#{@@artifact_info.pretty_inspect}"}
        end

        if !overrides[:output_dir].nil? and !overrides[:artifact_file_path].nil?
          raise %/
    both the artifact_file_path and output_dir were specified yet they do not match:
    output_dir:                      #{overrides[:artifact_file_name]}
    artifact_file_path's directory:  #{File.dirname(overrides[:artifact_file_path])}
    artifact_file_path:              #{overrides[:artifact_file_path]}
/ unless File.dirname(overrides[:artifact_file_path]) == overrides[:output_dir]
        end

        if !overrides[:artifact_file_name].nil? and !overrides[:artifact_file_path].nil?
          raise %/
    both the artifact_file_path and artifact_file_name were specified yet they do not match:
    artifact_file_name:              #{overrides[:artifact_file_name]}
    artifact_file_path's file name:  #{File.basename(overrides[:artifact_file_path])}
    artifact_file_path:              #{overrides[:artifact_file_path]}
/ unless File.basename(overrides[:artifact_file_path]) == overrides[:artifact_file_name]
        end

        @@artifact_info[:artifact_file_name] = "#{@@artifact_info[:artifact_base_file_name]}-#{@@artifact_info[:artifact_version]}.#{@@artifact_info[:artifact_file_extension]}" if overrides[:artifact_file_name].nil?
        @@artifact_info[:artifact_file_path] = "#{@@artifact_info[:output_dir]}/#{@@artifact_info[:artifact_file_name]}" if overrides[:artifact_file_path].nil?

        @@artifact_info
      end

    end
  end
end