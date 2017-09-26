require 'chef/data_bags/reader'
require 'jenkins_api_client'
require 'logging-helper'

class Jenkins
  extend LoggingHelper::LogToTerminal

  class << self

    @@data_bag_reader = nil
    def data_bag_reader
      return @@data_bag_reader unless @@data_bag_reader.nil?
      @@data_bag_reader = Chef::DataBag::Reader.new("#{$WORKSPACE_SETTINGS[:ecosystem][:paths][:ruby][:home]}/smithers")
    end

    @@credentials = nil
    def credentials
      return @@credentials unless @@credentials.nil?
      @@credentials = data_bag_reader.data_bag_item('resources', 'user')
    end

    def url
      "https://jenkins.#{$WORKSPACE_SETTINGS[:domain_name]}"
    end

    def ssl?
      url.start_with?('https')
    end

    @@client = nil
    def client
      return @@client unless @@client.nil?

      @@client = JenkinsApi::Client.new(
        server_url: url,
        ssl: ssl?,
        username: credentials[:username],
        password: credentials[:password],
        log_level: $WORKSPACE_SETTINGS[:logging][:log_level] == 'debug' ? 0 : 1
      )
    end

    def job
      client.job
    end

    @@current_build_details = nil
    def current_build_details
      return @@current_build_details unless @@current_build_details.nil?
      @@current_build_details = job.get_build_details("#{ENV["JOB_NAME"]}", "#{ENV["BUILD_NUMBER"]}")
    end

    @@current_build_items = []
    def current_build_items
      current_build_details['changeSet']['items'].each{|item|
        @@current_build_items.push item
      }
      @@current_build_items
    end

    @@current_build_commit_hash_list = []
    def current_build_commit_hash_list
      return @@current_build_commit_hash_list unless @current_build_commit_hash_list.nil?
      current_build_items.each{|item|
        @@current_build_commit_hash_list.push item['commitId']
      }
      debug "current_build_commit_hash_list is #{@@current_build_commit_hash_list}"
      @@current_build_commit_hash_list
    end

    def job_broken_by_commit_hash?(job_name, commit_hash)
      build_number = build_number_triggered_by_commit_hash(job_name, commit_hash, 5)
      result_of_triggered_build = build_result(job_name, build_number)

      puts "result of trggered build is #{result_of_triggered_build}"

      if result_of_triggered_build.eql?("FAILURE")
        puts "the #{job_name} was broken"
        return true
      else
        return false
      end
    end

    def build_number_triggered_by_commit_hash(job_name, commit_hash, look_back_this_many_builds)
      start = Time.now
      two_minutes = 120
      #after two minutes, scm polling will have begun to build the change
      while (Time.now - start) < two_minutes
        job.get_builds(job_name)[0...look_back_this_many_builds].each{|build|
          job.get_build_details(job_name, build['number'])['changeSet']['items'].each{|item|
            return build['number'] if item['commitId'].eql?(commit_hash)
          }
        }
        sleep 30
      end
      raise "Couldn't find a build in #{job_name} that was triggered by #{commit_hash}"
    end

    def build_result(job_name, build_number)
      if !job_has_build_number?(job_name, build_number)
        raise "There's no build result for #{job_name} and #{build_number} because the build doesn't exist."
      end

      build_result = nil
      #build result is nil while the build is executing
      until !build_result.nil?
        build_result = Jenkins.job.get_build_details(job_name, build_number)['result']
        sleep 30
      end

      build_result
    end

    def job_has_build_number?(job_name, build_number)
      job.get_builds(job_name).each{|build|
        if build['number'].eql?(build_number)
          return true
        end
      }
      return false
    end

    def files_affected_by_commit(commit_hash)
      commit_present = false
      files_affected_by_commit = []
      current_build_items.each{|item|
        if item['commitId'].eql? commit_hash
          commit_present = true
          item['affectedPaths'].each{|file_name|
            files_affected_by_commit.push file_name
          }
        end
      }
      raise "The commit you inputted was not present in the current build report" if !commit_present
      files_affected_by_commit
    end

    def smithers_to_job_short_name(smithers_file)
      job_short_name = smithers_file.split("/")[-2]
      debug "Smithers file is #{smithers_file} and your function said job_short_name is #{job_short_name}"
      job_short_name
    end

    def file_is_smithers?(file_name)
      debug "Is #{file_name} smiithers? your function said #{file_name.split("/")[-1].eql?("Smithersfile")}"
      file_name.split("/")[-1].eql?("Smithersfile")
    end

    def branch_has_jobs?(branch)
      if job.list("#{$WORKSPACE_SETTINGS[:project][:name]}-.-#{branch}-.-").eql? []
        return false
      else
        return true
      end
    end

  end
end
