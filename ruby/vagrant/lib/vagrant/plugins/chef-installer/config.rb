
module VagrantPlugins
  module ChefInstaller
    class Config < ::Vagrant.plugin("2", :config)

      attr_accessor :chef_version, :msi_download_url, :msi_file_name, :msi_sha1_checksum
      attr_accessor :rpm_download_url, :rpm_file_name, :rpm_sha1_checksum
      attr_accessor :osx_chef_version, :dmg_download_url, :dmg_file_name, :dmg_sha1_checksum

      def initialize
        super

        @chef_version = '12.9.38-1'

        @msi_download_url = "https://packages.chef.io/files/stable/chef/12.9.38/windows/2008r2/chef-client-#{@chef_version}-x64.msi"
        @msi_file_name = "chef-client-#{@chef_version}-x64.msi"
        @msi_sha1_checksum = "377ca30ea6aa0a8576d11597c02174c21a60a75e"

        @rpm_download_url = "https://packages.chef.io/stable/el/6/chef-#{@chef_version}.el6.x86_64.rpm"
        @rpm_file_name = "chef-#{@chef_version}.el6.x86_64.rpm"
        @rpm_sha1_checksum = "cd0d0701381118b52a9d52bb20eacc692a0c2707"

        @osx_chef_version = '12.9.38-1'

        @dmg_download_url = "https://packages.chef.io/stable/mac_os_x/10.11/chef-12.9.38-1.dmg"
        @dmg_file_name = "chef-12.9.38-1.dmg"
        @dmg_sha1_checksum = "906358ca5607c09c86ba9015a60cec39563cabae"

      end

      alias_method :to_hash, :instance_variables_hash

      def validate(machine)
        errors = Array.new

        { "chef installer configuration" => errors }
      end
    end
  end
end
