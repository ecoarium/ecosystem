require 'logging-helper'
require 'fileutils'
require 'common/version'
require 'facets/module/cattr'

class ArtifactRegistry

	extend LoggingHelper::LogToTerminal

  class << self

    @@artifacts = {}
    cattr_reader :artifacts    

    def artifact_info(name=:default)
      if !artifacts[name].nil?
        return artifacts[name]
      elsif name == :default
        add_artifact_info :default
      else
        raise %|
the artifact requested #{name.inspect} has not been added to the artifact registry.

maybe you are calling for it before it has been added?

maybe you got the name wrong? these are the current registered artifacts:
  * #{artifacts.keys.join("\n  * ")}

maybe you have not written the code to register the artifact. it would look like:

require 'artifact-registry'

ArtifactRegistry.add_artifact_info(:example_name)

there are optional

|
      end
    end

    def add_artifact_info(name, overrides={})
    	debug {"artifact_info(#{overrides.inspect})\n@@artifact_info:\n#{@@artifact_info.pretty_inspect}"}
    	return @@artifact_info if !@@artifact_info.nil? and overrides.empty?
    	if @@artifact_info.nil?
      	@@artifact_info = {
      		output_dir: "#{$WORKSPACE_SETTINGS[:paths][:production_path]}/#{$WORKSPACE_SETTINGS[:build_artifact_directory_name]}",
      		artifact_base_file_name: $WORKSPACE_SETTINGS[:project_name],
      		artifact_file_extension: "zip",
      		artifact_version: Common::Version.application_version
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