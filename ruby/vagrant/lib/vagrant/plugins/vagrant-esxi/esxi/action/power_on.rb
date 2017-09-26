require 'esxi/util/ssh'
require "timeout"

module VagrantPlugins
  module ESXi
    module Action
      class PowerOn

        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info I18n.t("vagrant_esxi.powering_on")
          ssh_util = VagrantPlugins::ESXi::Util::SSH
          
          ssh_util.esxi_host.communicate.execute("vim-cmd vmsvc/power.on '#{env[:machine].id}'")

          # wait for SSH to be available 
          env[:ui].info(I18n.t("vagrant_esxi.waiting_for_ssh"))
          Timeout.timeout(120) do
            until env[:machine].communicate.ready? or env[:interrupted]
              sleep 2
            end
          end
          
          @app.call env
        end
      end
    end
  end
end
