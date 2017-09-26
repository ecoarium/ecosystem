require "shell-helper"
require 'logging-helper'
require 'fileutils'

class Curl
  extend ShellHelper::Shell
  class << self
    def large_download(url, file_path)
      FileUtils.mkdir_p File.dirname(file_path) unless File.exist?(File.dirname(file_path))
      shell_command! "curl -m 86400 -C - -o #{file_path} -k -L --retry 5 \"#{url}\""
    end

    def large_upload(url:, file_path:, user_name: nil, password: nil, form_fields: {})
      cmd = ['curl']

      form_fields.each{|name,value|
        cmd.push "-F '#{name}=#{value}'"
      }

      cmd.push "-F 'file=@#{file_path}'"
      cmd.push "-u '#{user_name}:#{password}'" if !user_name.nil? or !password.nil?
      cmd.push "'#{url}'"

      shell_command! cmd.join(' ')
    end
  end
end
