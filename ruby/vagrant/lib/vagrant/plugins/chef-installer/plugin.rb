require "vagrant"

module VagrantPlugins
  module ChefInstaller
    class Plugin < Vagrant.plugin('2')
      name 'chef_installer'
      description <<-DESC
      This plugin ensures that Chef is installed
      DESC

      action_hook(:chef_installer, Plugin::ALL_ACTIONS) do |hook|
        require_relative 'action/install_chef'
        hook.after(Vagrant::Action::Builtin::Provision, Action::InstallChef)

        # The AWS provider < v0.4.0 uses a non-standard Provision action
        # on initial creation:
        #
        # mitchellh/vagrant-aws/blob/v0.3.0/lib/vagrant-aws/action.rb#L105
        #
        if defined? VagrantPlugins::AWS::Action::TimedProvision
          hook.after(VagrantPlugins::AWS::Action::TimedProvision,
                     Action::InstallChef)
        end
      end

      config(:chef_installer) do
        require_relative 'config'
        Config
      end
    end
  end
end
