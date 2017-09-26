require 'log4r'
require 'tempfile'

module VagrantPlugins
  module ChefInstaller
    module Action
      class InstallChef
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new(self.class.to_s)
        end

        def provision_enabled?(env)
          env.fetch(:provision_enabled, true)
        end

        def chef_provisioner?(env)
          env[:machine].config.vm.provisioners.any?{|provisioner|
            provisioner.type.to_s.downcase.start_with?('chef')
          }
        end

        def call(env)
          @app.call(env)

          return unless env[:machine].communicate.ready? and provision_enabled?(env) and chef_provisioner?(env)

          if env[:machine].config.vm.guest == :windows
            ensure_chef_on_windows_guest(env)
          elsif env[:machine].config.vm.guest == :darwin
            ensure_chef_on_osx_guest(env)
          else
            ensure_chef_on_nix_guest(env)
          end
        end

        def ensure_chef_on_windows_guest(env)
          begin
            env[:machine].communicate.execute("where.exe chef-solo")
          rescue
            download_url = env[:machine].config.chef_installer.msi_download_url
            file_name = env[:machine].config.chef_installer.msi_file_name
            sha1_checksum = env[:machine].config.chef_installer.msi_sha1_checksum
            chef_version = env[:machine].config.chef_installer.chef_version

            script = %^
@echo off
set dest=%HOMEPATH%\\Downloads\\#{file_name}
echo Downloading Chef #{chef_version} for Windows...
echo #{download_url}
powershell -command "(New-Object System.Net.WebClient).DownloadFile('#{download_url}', '%dest%')"
echo Installing Chef #{chef_version}
msiexec /q /i %dest%
^
            command = "C:\\Windows\\Temp\\chef-installer.cmd"
            file = Tempfile.new('chef-installer')

            begin
              file.binmode
              file.write(script)
              file.fsync
              file.close
              env[:machine].communicate.tap do |comm|
                comm.upload(file.path.to_s, command)
                comm.sudo(command) do |type, data|
                  if [:stderr, :stdout].include?(type)
                    next if data =~ /stdin: is not a tty/
                    env[:ui].info(data)
                  end
                end
              end
            ensure
              file.close
              file.unlink
            end
          end
        end

        def ensure_chef_on_osx_guest(env)
          begin
            env[:machine].communicate.sudo("which chef-solo")
          rescue
            download_url = env[:machine].config.chef_installer.dmg_download_url
            file_name = env[:machine].config.chef_installer.dmg_file_name
            osx_chef_version = env[:machine].config.chef_installer.osx_chef_version
            sha1_checksum = env[:machine].config.chef_installer.dmg_sha1_checksum

            script = %^
execute(){
  echo $@
  $@

  if [ "$?" != 0 ]; then
    echo "Failed to execute: $@"
    exit -1
  fi
}

download(){
  echo "downloading..."
  execute "curl -m 86400 -C - -o ./#{file_name} -k -L --retry 5 #{download_url}"
}

install_chef(){
  if [ ! -f './#{file_name}' ]; then
    download
  else
    if ! sha1sum ./#{file_name} 2>&1 | grep -q '#{sha1_checksum}'; then
      download
    else
      echo "already downloaded chef rpm"
    fi
  fi
  echo "installing chef..."

  execute "hdiutil attach ./#{file_name} -mountpoint /Volumes/chef_software"

  execute "sudo installer -pkg /Volumes/chef_software/chef-#{osx_chef_version}.pkg -target /"

  execute "hdiutil detach /Volumes/chef_software"
}

if ! which chef-solo ; then
  install_chef
else
  echo "chef #{File.basename(file_name)} is already installed"
fi
            ^

            command = "chmod +x /tmp/chef-installer && /tmp/chef-installer"
            file = Tempfile.new('chef-installer')

            begin
              file.binmode
              file.write(script)
              file.fsync
              file.close
              env[:machine].communicate.tap do |comm|
                comm.upload(file.path.to_s, '/tmp/chef-installer')
                comm.sudo(command) do |type, data|
                  if [:stderr, :stdout].include?(type)
                    next if data =~ /stdin: is not a tty/
                    env[:ui].info(data)
                  end
                end
              end
            ensure
              file.close
              file.unlink
            end
          end
        end

        def ensure_chef_on_nix_guest(env)
          begin
            env[:machine].communicate.sudo("which chef-solo")
          rescue
          	download_url = env[:machine].config.chef_installer.rpm_download_url
          	file_name = env[:machine].config.chef_installer.rpm_file_name
          	sha1_checksum = env[:machine].config.chef_installer.rpm_sha1_checksum

            script = %^
execute(){
  echo $@
  $@

  if [ "$?" != 0 ]; then
    echo "Failed to execute: $@"
    exit -1
  fi
}

download(){
  echo "downloading..."
  if ! rpm -q wget ; then
    install_wget
  fi
  execute "wget --no-check-certificate #{download_url}"
}

install_chef(){
  if [ ! -f './#{file_name}' ]; then
    download
  else
    if ! sha1sum ./#{file_name} 2>&1 | grep -q '#{sha1_checksum}'; then
      download
    else
      echo "already downloaded chef rpm"
    fi
  fi
  echo "installing chef..."
  execute "rpm -Uvh --replacepkgs #{file_name}"
}

install_wget(){
  echo "installing wget..."
  execute "yum -y install wget"
}

if ! rpm -q chef | grep -q '#{File.basename(file_name)}' ; then
  install_chef
else
  echo "chef #{File.basename(file_name)} is already installed"
fi
^

            command = "chmod +x /tmp/chef-installer && /tmp/chef-installer"
            file = Tempfile.new('chef-installer')

            begin
              file.binmode
              file.write(script)
              file.fsync
              file.close
              env[:machine].communicate.tap do |comm|
                comm.upload(file.path.to_s, '/tmp/chef-installer')
                comm.sudo(command) do |type, data|
                  if [:stderr, :stdout].include?(type)
                    next if data =~ /stdin: is not a tty/
                    env[:ui].info(data)
                  end
                end
              end
            ensure
              file.close
              file.unlink
            end
          end
        end
      end
    end
  end
end
