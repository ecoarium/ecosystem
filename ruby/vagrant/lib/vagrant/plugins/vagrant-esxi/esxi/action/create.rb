require "i18n"
require "open3"
require "vagrant/util/subprocess"
require 'esxi/util/ssh'

module VagrantPlugins
  module ESXi
    module Action
      class Create

        def initialize(app, env)
          @app = app
        end

        def call(env)
          config = env[:machine].provider_config

          box = env[:machine].box
          box = env[:global_config].box if box.nil?

          box_name = env[:machine].config.vm.box
          unique_machine_name = "#{env[:machine].name}-#{SecureRandom.uuid}"
          if unique_machine_name.length > 80
            length_secure_random_hex = (80 - "#{env[:machine].name}-".length) /2
            unique_machine_name = "#{env[:machine].name}-#{SecureRandom.hex(length_secure_random_hex)}"
          end
          ssh_util = VagrantPlugins::ESXi::Util::SSH

          unless ssh_util.machine_exist?(env[:machine].id)
            env[:ui].info(I18n.t("vagrant_esxi.copying"))
            vmx_file = Dir.glob(box.directory.join('*.vmx')).sort!.fetch(0)

            ovftool = '/usr/bin/ovftool'
            if RbConfig::CONFIG['host_os'].include?('darwin')
              ovftool = '/Applications/VMware Fusion.app/Contents/Library/VMware OVF Tool/ovftool'
            end

            esxi_import_command = [
              ovftool,
              "--datastore=#{config.datastore}",
              "--diskMode=sparse",
              "--name=#{unique_machine_name}",
              "--network=#{config.network}",
              "--noImageFiles",
              "--noSSLVerify",
              "--overwrite",
              "--privateKey=#{config.ssh_key_path}",
              vmx_file,
              "vi://#{config.user}:#{config.password}@#{config.host}"
            ]

            execute_ovftool(esxi_import_command, env)
          end

          id = nil
          ssh_util.esxi_host.communicate.execute("vim-cmd vmsvc/getallvms | grep #{unique_machine_name} | awk '{print $1}'") do |type, data|
           if [:stderr, :stdout].include?(type)
             id = data.chomp
           end
          end

          env[:machine].id = id

          @app.call env
        end

        def execute_ovftool(command, env)
          esxi_import = Vagrant::Util::Subprocess.execute(*command, notify: [:stdout, :stderr]) do |type, data|
            if type == :stderr
              env[:ui].error(data)
            else
              env[:ui].info(data)
            end
          end

          if esxi_import.exit_code != 0
            raise esxi_import.stderr
          end
        end
      end
    end
  end
end
