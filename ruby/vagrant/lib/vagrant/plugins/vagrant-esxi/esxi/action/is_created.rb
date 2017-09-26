require 'esxi/util/ssh'

module VagrantPlugins
  module ESXi
    module Action
      class IsCreated
        
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:result] = VagrantPlugins::ESXi::Util::SSH.machine_exist?(env[:machine].id)

          @app.call env
        end
      end
    end
  end
end
