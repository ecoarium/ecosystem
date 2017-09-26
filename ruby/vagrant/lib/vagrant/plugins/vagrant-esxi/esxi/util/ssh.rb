require "log4r"
require "pathname"
require "tempfile"
require 'esxi/util/mock_machine'

module VagrantPlugins
  module ESXi
    module Util
      class SSH
        class << self
          def esxi_host
            return @esxi_host unless @esxi_host.nil?

            @esxi_host = MockMachine.new
          end

          def machine_exist?(id)
            return false if id.nil? or id.empty?
            esxi_host.communicate.execute("vim-cmd vmsvc/get.summary #{id}", :error_check => false) == 0
          end

          def machine_running?(id)
            esxi_host.communicate.execute("vim-cmd vmsvc/power.getstate #{id} | grep 'Powered on'", :error_check => false) == 0
          end

          def get_vm_path(id)
            vm_path_name = nil
            esxi_host.communicate.execute("vim-cmd vmsvc/get.summary #{id}") do |type, data|
             if [:stderr, :stdout].include?(type)
               vm_path_name_match = data.match(/vmPathName\s+=\s+"(.*)"/)
               vm_path_name = vm_path_name_match.captures[0].strip if vm_path_name_match
             end
            end
            vm_path_name
          end

          def get_vm_name(id)
            vm_name = nil
            esxi_host.communicate.execute("vim-cmd vmsvc/get.summary #{id}") do |type, data|
             if [:stderr, :stdout].include?(type)
               vm_name_match = data.match(/name\s+=\s+"(.*)"/)
               vm_name = vm_name_match.captures[0].strip if vm_name_match
             end
            end
            vm_name
          end

          def get_vmx_path(id)
            match = get_vm_path(id).match(/^\[(.*)\]\s+(.*)$/)
            data_store = match.captures[0]
            vmx_partial_path = match.captures[1]

            "/vmfs/volumes/#{data_store}/#{vmx_partial_path}"
          end

          def get_originial_vmx_path(id)
            vmx_path = get_vmx_path(id)
            "#{vmx_path}.orig"
          end

          def write_vmx_file(vmx_file_contnent, id)
            ensure_originial_vmx_file_exists(id)

            vmx_path = get_vmx_path(id)

            with_file(vmx_file_contnent){|local_file_path|
              esxi_host.communicate.upload(local_file_path.to_s, vmx_path)
            }
          end

          def ensure_originial_vmx_file_exists(id)
            originial_vmx_path = get_originial_vmx_path(id)
            vmx_path = get_vmx_path(id)

            script = %^
if [[ ! -e "#{originial_vmx_path}" ]]; then
  cp "#{vmx_path}" "#{originial_vmx_path}"
fi
^

            run_script(script)
          end

          def get_originial_vmx_file_content(id)
            ensure_originial_vmx_file_exists(id)
            
            originial_vmx_path = get_originial_vmx_path(id)

            originial_vmx_file_content = StringIO.new
            esxi_host.communicate.execute("cat #{originial_vmx_path}") do |type, data|
              originial_vmx_file_content.puts data
            end
            originial_vmx_file_content.string
          end

          @@ui = nil
          def ui
            return @@ui unless @@ui.nil?
            @@ui = ::Vagrant::UI::Colored.new
          end

          def run_script(script)
            upload_path = "/tmp/vagrant-shell"
            command = "chmod +x #{upload_path} && #{upload_path}"

            with_file(script) do |path|
              # Upload the script to the esxi_host
              esxi_host.communicate.tap do |comm|

                comm.upload(path.to_s, upload_path)

                ui.info("executing commands over ssh on esxi host...")

                # Execute it with sudo
                comm.execute(command, sudo: false) do |type, data|
                  if [:stderr, :stdout].include?(type)
                    # Output the data with the proper color based on the stream.
                    color = type == :stdout ? :green : :red

                    options = {
                      new_line: false,
                      prefix: false,
                    }
                    options[:color] = color

                    ui.info(data, options)
                  end
                end
              end
            end
          end

          protected

          def with_file(content)
            file = Tempfile.new('vagrant-shell')
            file.binmode

            begin
              file.write(content)
              file.fsync
              file.close
              yield file.path
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