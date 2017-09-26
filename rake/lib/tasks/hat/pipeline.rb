require 'nexus'
require 'jenkins/version'
require 'common/version'
require 'fileutils'

puts "

################################## BEGIN JENKINS METADATA ##################################
#{Jenkins::Version.version_properties}
################################### END JENKINS METADATA ###################################

"

property_file = $WORKSPACE_SETTINGS[:paths][:project][:jenkins][:down][:stream][:job][:properties][:file]
property_file_directory = File.dirname(property_file)

FileUtils.mkdir_p(property_file_directory) unless File.exist?(property_file_directory)
File.open(property_file, "w"){|file|
  file.puts Jenkins::Version.version_properties
}

def upload
  artifact_info = Compiler::Maven.artifact_info

  Nexus.upload_artifact(
    group_id:       "#{$WORKSPACE_SETTINGS[:nexus][:base_coordinates][:group_id]}.#{Common::Version.application_branch}",
    artifact_id:    artifact_info[:artifact_base_file_name],
    artifact_ext:   artifact_info[:artifact_file_extension],
    version:        artifact_info[:artifact_version],
    repository:     $WORKSPACE_SETTINGS[:nexus][:repos][:release],
    artifact_path:  artifact_info[:artifact_file_path]
  )

  commit_hash_file = $WORKSPACE_SETTINGS[:paths][:project][:jenkins][:commit][:hash][:file]
  commit_hash_file_directory = File.dirname(commit_hash_file)

  FileUtils.mkdir_p(commit_hash_file_directory) unless File.exist?(commit_hash_file_directory)
  File.open(commit_hash_file, "w"){|file|
    file.puts Common::Version.application_commit_hash
  }

  Nexus.upload_artifact(
    group_id:       "#{$WORKSPACE_SETTINGS[:nexus][:base_coordinates][:group_id]}.#{Common::Version.application_branch}",
    artifact_id:    artifact_info[:artifact_base_file_name],
    artifact_ext:   "#{artifact_info[:artifact_file_extension]}.commithash",
    version:        artifact_info[:artifact_version],
    repository:     $WORKSPACE_SETTINGS[:nexus][:repos][:release],
    artifact_path:  commit_hash_file
  )

end

task :upload => [:clean, :rt_deploy] do
  upload
end

desc "generate cobertura xml report from the jacoco xml report"
task :jacoco_to_cobertura, :jacoco_file_path, :source_patten, :cobertura_file_path do |task, args|
  if args.jacoco_file_path == nil then
      raise "no JaCoCo XML file path specified"
  end
  if args.source_patten == nil then
      raise "no path to source directories specified"
  end
  if args.cobertura_file_path = nil then
      raise "no Cobertura output file path specified"
  end

  jacoco_to_cobertura(
    jacoco_file_path: args.jacoco_file_path,
    source_patten: args.source_patten,
    cobertura_file_path: args.cobertura_file_path
  )
end

def jacoco_to_cobertura(jacoco_file_path:, source_patten:, cobertura_file_path:)
  puts "Begin to convert the jacoco report to cobertura xml report!"

  project_home = "#{$WORKSPACE_SETTINGS[:paths][:project][:home]}"
  cobertura_file = File.join(project_home, "#{cobertura_file_path}")
  jacoco_file = File.join(project_home, "#{jacoco_file_path}")
  source_patten = File.join(project_home, "#{source_patten}")
  cover2cover_file = File.join(source_patten, 'cover2cover.py')

  if File.exists? cobertura_file then
    File.delete(cobertura_file)
  end
  FileUtils.mkdir_p(File.dirname(cobertura_file))

  unless File.exists? cover2cover_file then
    puts "Download the cover2cover python file from nexus sever."

  Nexus.download_artifact(
      group_id:          "JaCoCo2Cobertura",
      artifact_id:       "JaCoCo2Cobertura",
      extra_coordinates: {e: "py"},
      version:           "1.0.0.0",
      repository:        "EcoSystem",
      file_path:         "#{cover2cover_file}"
    )
  end

  shell_command!(
     "python cover2cover.py #{jacoco_file} > #{cobertura_file}",
      cwd: "#{source_patten}",
    )
end
