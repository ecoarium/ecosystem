require 'facets/module/cattr'
require 'shell-helper'
require 'logging-helper'
require 'safe/io'
require 'fileutils'
require 'rake/dsl_definition'

module Vagrant
  module Shell
    include ShellHelper::Shell
    include LoggingHelper::LogToTerminal
    include ::Rake::DSL

    cattr_reader :vagrant_context_path, :vagrant_lib_path, :chef_home_path, :cookbooks_path
    cattr_reader :project_home, :vagrant_context, :project, :vagrant_file
    cattr_reader :vagrant_state_dir, :berks_lock
    
  	@@project_home = $WORKSPACE_SETTINGS[:paths][:project][:home]
  	@@vagrant_context = $WORKSPACE_SETTINGS[:vagrant][:context]
  	@@vagrant_file = $WORKSPACE_SETTINGS[:vagrant][:vagrantfile]
    @@vagrant_state_dir = $WORKSPACE_SETTINGS[:paths][:project][:deploy][:vagrant][:state]
    @@vagrant_context_path = $WORKSPACE_SETTINGS[:paths][:project][:deploy][:vagrant][:context][:home]
    @@vagrant_lib_path = $WORKSPACE_SETTINGS[:paths][:project][:deploy][:vagrant][:lib]
    @@chef_home_path = $WORKSPACE_SETTINGS[:paths][:project][:deploy][:chef][:home]
    @@cookbooks_path = $WORKSPACE_SETTINGS[:paths][:project][:deploy][:chef][:cookbook][:home]
  	@@project = $WORKSPACE_SETTINGS[:project][:name]

    def berks_files
      Dir.glob("#{$WORKSPACE_SETTINGS[:paths][:project][:deploy][:vagrant][:context][:home]}/Berksfile*")
    end

  	def default_sources
  		src = [
      	vagrant_file,
      	vagrant_lib_path,
      	chef_home_path
    	]
    	src.concat berks_files
    	src
  	end

    def current?(target, sources, source_exclusions=[])
    	return false unless File.exist?(target)
      src = []

    	sources.each{ |source|
    		next unless File.exist?(source)

    		if File.file?(source)
    			src << source unless should_exclude?(source, source_exclusions)
    		else
	      	Dir.glob("#{source}/**/*").select{ |source_file|
	      		next if File.directory?(source_file) or should_exclude?(source_file, source_exclusions)
	      		src << source_file
	      	}
	      end
    	}

      uptodate?(target,src)
    end

    def should_exclude?(file, exclusions)
    	exclusions.any?{|exclusion|
				result = false
				if exclusion.has_key?(:pattern)
					result = file =~ exclusion[:pattern]
				elsif exclusion.has_key?(:file)
					result = file == exclusion[:file]
  			else
  				raise %/
exclusion type not supported #{exclusion.pretty_inspect}

supported exclusions include:

{
	file: '\/path\/to\/file'
}

{
	pattern: \/regex\/
}

/
  			end
  			result
			}
    end

    def raw_vagrant_execution(command, args={})
      args = {
        cwd: vagrant_context_path,
        quiet: true
      }.merge(args)
      
      shell_command! "vagrant #{command}", args
    end

  end
end
