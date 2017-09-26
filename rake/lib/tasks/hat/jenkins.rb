require 'jenkins'
require 'logging-helper'
require 'shell-helper'
require 'smithers'
require 'git'
require 'date'
require 'json'
require 'chef/data_bags/reader'


include LoggingHelper::LogToTerminal
include ShellHelper::Shell

desc "create the pipeline management jobs: creator and destroyer"
task :create_or_update_pipeline_management do
  Dir.glob("#{$WORKSPACE_SETTINGS[:ecosystem][:paths][:ruby][:home]}/smithers/jobs/*.rb"){|smithers_file|
    Smithers::SmithersFile.new(
      smithers_file_path: smithers_file,
      jenkins_url: Jenkins.url,
      jenkins_ssl: Jenkins.ssl?,
      jenkins_username: Jenkins.credentials[:username],
      jenkins_password: Jenkins.credentials[:password]
    ).run
  }
end

desc "create or update jobs"
task :create_or_update_jobs do
  next unless create_or_update?
  puts "creating or updating"

  Dir.glob("#{$WORKSPACE_SETTINGS[:paths][:project][:jenkins][:home]}/**/Smithersfile"){|smithers_file|
    debug smithers_file
    Dir.chdir(File.dirname(smithers_file)){
      Smithers::SmithersFile.new(
        smithers_file_path: 'Smithersfile',
        jenkins_url: Jenkins.url,
        jenkins_ssl: Jenkins.ssl?,
        jenkins_username: Jenkins.credentials[:username],
        jenkins_password: Jenkins.credentials[:password],
        to_stdout: false
      ).run
    }
  }
end

def create_or_update?
    return true if Jenkins.branch_has_jobs?(Git.branch_name)

    debug "#{Git.branch_name} has no jobs"
    puts "#{Git.branch_name} has no jobs"

    smithers_changed = false
    Jenkins.current_build_commit_hash_list.each{|commit_hash|
      #merge commits will not appear here because Jenkins doesn't list them
      Jenkins.files_affected_by_commit(commit_hash).each{|affected_file|
        debug "file found associated with current build is #{affected_file}"
        if Jenkins.file_is_smithers?(affected_file)
            debug "smithers file has file name: #{affected_file}"
            smithers_changed = true
            break
        end
      }
      break if smithers_changed
    }

    if smithers_changed
      return true
    else
      #merge triggered the build
      return false
    end
end

desc "delete jobs for branches that have been deleted"
task :delete_orphaned_jobs do
  Git.fetch_and_prune_remote_branches

  Jenkins.job.list("^#{$WORKSPACE_SETTINGS[:project][:name]}-\.-.*-\.-.*").each{|job_name|
    project_name, branch_name, job_short_name = job_name.split($WORKSPACE_SETTINGS[:delimiter])

    next if job_short_name.nil?
      debug {"checking if branch #{branch_name} exists for #{job_name}"}
    unless Git.remote_branches.include?(branch_name)
      puts "deleting job #{job_name}, branch #{branch_name} does not exist"
      Jenkins.job.delete(job_name)
    end
  }
end

desc "list all projects"
task :list_all_projects do
  puts Jenkins.job.list_all.collect{|job_name|
    project_name, branch_name, job_short_name = job_name.split($WORKSPACE_SETTINGS[:delimiter])

    project_name
  }.uniq
end

desc "list matching jobs"
task :list_matching_jobs, :pattern do |t, args|
  Jenkins.job.list(args.pattern).each{|job_name|
    project_name, branch_name, job_short_name = job_name.split($WORKSPACE_SETTINGS[:delimiter])

    puts "job_name: #{job_name}
    project_name:   #{project_name}
    branch:         #{branch_name}
    job_short_name: #{job_short_name}
    "

  }
end

def job_exclutions_from_deletion
  [
    /^next$/
  ]
end

def legacy_or_old_job?(job_details)

  date = job_details['description'].split($WORKSPACE_SETTINGS[:delimiter])[1]
  return true if date.nil?

  created_date =  date.strip.split('"')[3]
  date_string =  Date.strptime(created_date.to_s , '%Y-%m-%d')
  days_old = (Date.today - date_string).to_i
  return days_old > 10

end

desc "delete disabled jobs"
task :delete_disabled_jobs, :dry_run do |t, args|
  dry_run = args.dry_run == 'false' ? false : true
  puts "dry_run -> #{dry_run.inspect}"

  Jenkins.job.list("^#{$WORKSPACE_SETTINGS[:project][:name]}-\.-.*-\.-.*").each{|job|

    job_details = Jenkins.job.list_details(job)

    if legacy_or_old_job?(job_details) && job_details['color'] == 'disabled' && job_details['builds'].empty?
      project_name, branch_name, job_short_name = job.split($WORKSPACE_SETTINGS[:delimiter])

      next if job_short_name.nil?
        puts "checking if branch #{branch_name} is excluded from deletion for #{job}"
      unless job_exclutions_from_deletion.any?{|exclusion_pattern| branch_name =~ exclusion_pattern}
        warn "deleting job #{job}"
        Jenkins.job.delete(job) unless dry_run
      end
    end
 }
end

desc "list jenkins slaves"
task :list_jenkins_slaves do
  Jenkins.client.node.list.each{|node_name|
    next if node_name == 'master'

    response = Jenkins.client.api_post_request(
      "/computer/#{node_name}/scriptText",
      {
        'script' => 'import hudson.model.Computer.ListPossibleNames
def names = (new ListPossibleNames()).call()
println names[0]
'
      },
      true
    )
    puts "#{node_name} -> #{response.body}"
  }
end
