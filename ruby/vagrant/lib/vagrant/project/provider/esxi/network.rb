require 'vagrant/project/mixins/configurable'
require 'esxi/util/ssh'

module Vagrant
  module Project
    module Provider
      class ESXI
        module Config
          class Network
            include Vagrant::Project::Mixins::Configurable
            include LoggingHelper::LogToTerminal

            attr_reader :ip_address

            def configure_this(vagrant_machine, esxi)
              set_ip_address(vagrant_machine)
            end

            def set_ip_address(vagrant_machine)
              @ip_address = "#{vagrant_machine.name}:ip_address"

              if File.exist?(vagrant_machine.id_file)
                machine_id = IO.read(vagrant_machine.id_file)

                ssh_util = VagrantPlugins::ESXi::Util::SSH

                debug {"finding the ip address for #{vagrant_machine.name}:#{machine_id}:#{vagrant_machine.id_file}"}
                ssh_util.esxi_host.communicate.execute("vim-cmd vmsvc/get.guest '#{machine_id}'") do |type, data|
                  if [:stderr, :stdout].include?(type)
                    debug {data}
                    ip_address_match = data.match(/^\s+ipAddress\s+=\s+"(.*?)"/m)
                    @ip_address = ip_address_match.captures[0].strip if ip_address_match
                  end
                end
              end

              @ip_address
            end
          end
        end
      end
    end
  end
end