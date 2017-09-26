require 'shell-helper'
require 'fileutils'
require 'sshkey'
require 'securerandom'
require 'shell-helper'

module SSHHelper
  class SSHKeys
    include ShellHelper::Shell

    def create_ssh_key_pair(directory, opts=nil)
      ssh_dir = File.expand_path(".ssh", directory)
      private_key_path = File.expand_path("id_rsa", ssh_dir)
      public_key_path = File.expand_path("id_rsa.pub", ssh_dir)

      unless File.exist? private_key_path
        opts = {
          :passphrase => SecureRandom.hex
        }.merge(opts || {})

        key_pair = SSHKey.generate(:type => "RSA", :bits => 1024, :passphrase => opts[:passphrase])

        FileUtils.mkdir_p(ssh_dir)
        shell_command! "chmod 0700 #{ssh_dir}"

        File.open(private_key_path, 'w') do |file|
          file.write(key_pair.private_key)
        end
        shell_command! "chmod 0600 #{private_key_path}"

        File.open(public_key_path, 'w') do |file|
          file.write(key_pair.ssh_public_key)
        end
        shell_command! "chmod 0644 #{public_key_path}"

        ssh_public_key = key_pair.ssh_public_key
      else
        ssh_public_key = File.read(public_key_path)
      end

      {private_key_path: private_key_path, public_key_path: public_key_path, ssh_public_key: ssh_public_key}
    end
  end
end