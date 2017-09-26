require "vagrant"
require "vagrant/action/builder"
require "vagrant/action/builtin/synced_folders"

module VagrantPlugins
  module ESXi
    module Action
      include Vagrant::Action::Builtin

      # Vagrant commands
      def self.action_destroy
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsRunning do |env, b2|
            if [:result]
                b2.use PowerOff
                next
            end
          end
          b.use Destroy
        end
      end

      def self.action_provision
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            if !env[:result]
              b2.use MessageNotCreated
              next
            end
            
            b2.use Call, IsRunning do |env, b3|
              if !env[:result]
                b3.use MessageNotRunning
                next
              end
              
              b3.use Provision
              b3.use ::Vagrant::Action::Builtin::SyncedFolders
            end
          end
        end
      end

      def self.action_ssh
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            if !env[:result]
              b2.use MessageNotCreated
              next
            end
            
            b2.use Call, IsRunning do |env, b3|
              if !env[:result]
                b3.use MessageNotRunning
                next
              end
              
              b3.use SSHExec
            end
          end
        end
      end

      def self.action_ssh_run
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            if !env[:result]
              b2.use MessageNotCreated
              next
            end
            
            b2.use Call, IsRunning do |env, b3|
              if !env[:result]
                b3.use MessageNotRunning
                next
              end
              
              b3.use SSHRun
            end
          end
        end
      end

      def self.action_reload
        Vagrant::Action::Builder.new.tap do |b|
          b.use Call, IsCreated do |env1, b2|
            if !env1[:result]
              b2.use MessageNotCreated
              next
            end

            b2.use ConfigValidate
            b2.use action_halt
            b2.use action_up
          end
        end
      end

      def self.action_up
        Vagrant::Action::Builder.new.tap do |b|
          b.use Call, IsCreated do |env, b2|
            if !env[:result]
              b2.use HandleBox
            end
          end

          b.use ConfigValidate

          b.use Call, IsCreated do |env, b2|
            if env[:result]
              b2.use MessageAlreadyCreated
              next
            end

            b2.use Create
            b2.use Call, IsRunning do |env, b3|
              if env[:result]
                b3.use PowerOff
              end
            end
          end

          b.use Call, IsRunning do |env, b2|
            if !env[:result]
              b2.use Customize
              b2.use PowerOn
              
              b2.use Provision
              b2.use ::Vagrant::Action::Builtin::SyncedFolders
            end
          end

        end
      end

      def self.action_halt
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            if !env[:result]
              b2.use MessageNotCreated
              next
            end
            
            b2.use Call, IsRunning do |env, b3|
              if !env[:result]
                b3.use MessageNotRunning
                next
              end
              
              b3.use PowerOff
            end
          end
        end
      end

      # ESXi specific actions
      def self.action_get_state
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            if env[:result]
              b.use Call, IsRunning do |env, b2|
                if env[:result]
                  env[:machine_state_id] = :running
                else
                  env[:machine_state_id] = :poweroff
                end
              end
            else
              env[:machine_state_id] = :not_created
            end
          end
        end
      end

      def self.action_get_ssh_info
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use GetSshInfo
        end
      end

      # autoload
      action_root = Pathname.new(File.expand_path("../action", __FILE__))
      autoload :Create, action_root.join("create")
      autoload :Destroy, action_root.join("destroy")
      autoload :GetSshInfo, action_root.join("get_ssh_info")
      autoload :Customize, action_root.join("customize")
      autoload :IsCreated, action_root.join("is_created")
      autoload :IsRunning, action_root.join("is_running")
      autoload :MessageAlreadyCreated, action_root.join("message_already_created")
      autoload :MessageNotCreated, action_root.join("message_not_created")
      autoload :MessageNotRunning, action_root.join("message_not_running")
      autoload :PowerOff, action_root.join("power_off")
      autoload :PowerOn, action_root.join("power_on")
    end
  end
end
