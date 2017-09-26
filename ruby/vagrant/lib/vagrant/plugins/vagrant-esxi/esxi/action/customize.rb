require 'esxi/util/ssh'

module VagrantPlugins
  module ESXi
    module Action
      class Customize

        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info "applying any customizations"

          config = env[:machine].provider_config
          ssh_util = VagrantPlugins::ESXi::Util::SSH

          originial_vmx_file_content = ssh_util.get_originial_vmx_file_content(env[:machine].id)
          vmx = parse_vmx_file(originial_vmx_file_content)

          config.customizations.each{|customization|
            vmx[customization[:key]] = customization[:value]
          }

          vmx_file_contnent = flatten_vmx_structure(vmx)

          ssh_util.write_vmx_file(vmx_file_contnent, env[:machine].id)
          ssh_util.esxi_host.communicate.execute("vim-cmd vmsvc/reload '#{env[:machine].id}'")

          vmx_path = ssh_util.get_vmx_path(env[:machine].id)
          config.disks.each{|disk|
            add_disk(ssh_util, disk, env[:machine].id, vmx_path)
          }
          ssh_util.esxi_host.communicate.execute("vim-cmd vmsvc/reload '#{env[:machine].id}'")

          @app.call env
        end

        def add_disk(ssh_util, disk, id, vmx_path)
          vm_path = File.dirname(vmx_path)
          disk_file_name = "disk.#{disk[:controller_id]}.#{disk[:port]}.vmdk"
          script = %^
cd "#{vm_path}"

if [[ ! -e "#{disk_file_name}" ]]; then
  echo "making new #{disk[:size]}G disk: #{disk_file_name}"
  vmkfstools -c #{disk[:size]}G -d thin -a lsilogic #{disk_file_name}
fi

if ! grep -q '#{disk_file_name}' #{vmx_path} ; then
  echo "registering new disk to controller:#{disk[:controller_id]} port:#{disk[:port]}"
  vim-cmd vmsvc/device.diskaddexisting #{id} #{vm_path}/#{disk_file_name} #{disk[:controller_id]} #{disk[:port]}
fi
^
          ssh_util.run_script(script)
        end

        def parse_vmx_file(content)
          vmx = {}

          content.split("\n").each{|line|
            match = line.match(/^(.*)\s+=\s+"(.*)"$/)
            key = match.captures[0]
            value = match.captures[1]
            vmx[key] = value
          }

          vmx
        end

        def flatten_vmx_structure(vmx)
          content = StringIO.new

          vmx.each{|key,value|
            content.puts "#{key} = \"#{value}\""
          }

          content.string
        end
      end
    end
  end
end
