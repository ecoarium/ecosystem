require 'esxi/util/ssh'

module VagrantPlugins
  module ESXi
    module Action
      class PowerOff

        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info I18n.t("vagrant_esxi.powering_off")

          ssh_util = VagrantPlugins::ESXi::Util::SSH
          
          ssh_util.esxi_host.communicate.execute("vim-cmd vmsvc/power.off '#{env[:machine].id}'")

          @app.call env
        end
      end
    end
  end
end
