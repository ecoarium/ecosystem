
module VagrantPlugins
  module AWS
    module Action
      include Vagrant::Action::Builtin

      def self.action_provision
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            if !env[:result]
              b2.use MessageNotCreated
              next
            end
            
            b2.use Provision
            b2.use SyncedFolders
          end
        end
      end

      class TerminateInstance
        def release_address(env,eip)
          
        end
      end
    end
  end
end
