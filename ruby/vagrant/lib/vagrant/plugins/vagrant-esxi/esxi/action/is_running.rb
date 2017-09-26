require 'esxi/util/ssh'

module VagrantPlugins
  module ESXi
    module Action
      class IsRunning
        
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:result] = VagrantPlugins::ESXi::Util::SSH.machine_running?(env[:machine].id)

          @app.call env
        end
      end
    end
  end
end
