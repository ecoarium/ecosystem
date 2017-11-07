require 'shell-helper'
require 'logging-helper'

class Git
	extend ShellHelper::Shell
	extend LoggingHelper::LogToTerminal

  class << self

		def user(dir=$WORKSPACE_SETTINGS[:paths][:project][:home])
			process = shell_command! 'git config user.name', cwd: dir, live_stream: nil
      process.stdout.strip
		end

		def user_email(dir=$WORKSPACE_SETTINGS[:paths][:project][:home])
			process = shell_command! 'git config user.email', cwd: dir, live_stream: nil
      process.stdout.strip
		end

    def fetch_and_prune_remote_branches(dir=$WORKSPACE_SETTINGS[:paths][:project][:home])
      shell_command! 'git fetch -p', cwd: dir
    end

    @@remote_branches = {}
    def remote_branches(dir=$WORKSPACE_SETTINGS[:paths][:project][:home])
      return @@remote_branches[dir] unless @@remote_branches[dir].nil?

      result = shell_command! "git branch -r | grep -v HEAD", cwd: dir, live_stream: nil
      @@remote_branches[dir] = result.stdout.split("\n").collect{|branch_name|
        branch_name[/origin\/(.*)/,1]
      }
    end

		@@branch_names = {}
    def branch_name(dir=$WORKSPACE_SETTINGS[:paths][:project][:home])
    	return @@branch_names[dir] unless @@branch_names[dir].nil?

      if ENV['GIT_BRANCH'].nil?
      	process = shell_command! "git rev-parse --abbrev-ref HEAD", cwd: dir, live_stream: nil
        @@branch_names[dir] = process.stdout.strip
      else
				if ENV['GIT_BRANCH'].include? '/'
      		@@branch_names[dir] = ENV['GIT_BRANCH'].split('/')[1]
				else
					@@branch_names[dir] = ENV['GIT_BRANCH']
				end
      end

      @@branch_names[dir]
    end

    @@tag_names = {}
    def tag_name(dir=$WORKSPACE_SETTINGS[:paths][:project][:home])
      return @@tag_names[dir] unless @@tag_names[dir].nil?

      process = shell_command "git describe --exact-match --tags $(git log -n1 --pretty='%h')", cwd: dir, live_stream: nil

      if process.error? and process.stderr.strip.include?('fatal: no tag exactly matches')
        return nil
      elsif process.error?
        process.error!
      else
        @@tag_names[dir] = process.stdout.strip
      end

      @@tag_names[dir]
    end

    @@versions = {}
    def version(dir=$WORKSPACE_SETTINGS[:paths][:project][:home])
      return @@versions[dir] unless @@versions[dir].nil?

      process = shell_command! "git rev-list --no-merges --count #{commit_hash(dir)} -- .", cwd: dir, live_stream: nil
      @@versions[dir] = process.stdout.strip

      @@versions[dir]
    end

    @@commit_hashs = {}
    def commit_hash(dir = $WORKSPACE_SETTINGS[:paths][:project][:home])
      return @@commit_hashs[dir] unless @@commit_hashs[dir].nil?

      process = shell_command! 'git rev-parse HEAD', cwd: dir, live_stream: nil
      @@commit_hashs[dir] = process.stdout.strip

      @@commit_hashs[dir]
    end

    def up_to_date?(dir = $WORKSPACE_SETTINGS[:paths][:project][:home])
      status_command = "git status -uno -u"
      process = shell_command! "#{status_command}", cwd: dir

      output = process.stdout

      up_to_date = output.include?('Your branch is up-to-date with')
      no_unstaged_files = !output.include?('Changes not staged for commit')
      no_untracked_files = !output.include?('Untracked files')

      up_to_date and no_unstaged_files and no_untracked_files
    end
  end
end
