require 'vagrant/plugins/berkshelf/vagrant'

module Berkshelf
  module Vagrant
    class Plugin < ::Vagrant.plugin("2")

      name "berkshelf"
      description <<-DESC
      Automatically make available cookbooks to virtual machines provisioned by Chef Solo
      or Chef Client using Berkshelf.
      DESC


      [:machine_action_up, :machine_action_reload, :machine_action_provision].each do |action|
        action_hook(:berkshelf_provision, action) do |hook|
          hook.after(::Vagrant::Action::Builtin::ConfigValidate, Action.setup)
          hook.before(::Vagrant::Action::Builtin::Provision, Action.install)
        end
      end

      action_hook(:berkshelf_cleanup, :machine_action_destroy) do |hook|
        hook.before(::Vagrant::Action::Builtin::DestroyConfirm, Action.clean)
        hook.before(::Vagrant::Action::Builtin::DestroyConfirm, Action.setup)
      end


      config(:berkshelf) do
        Berkshelf::Vagrant::Config
      end

      command "berks-ls" do
        require_relative "command/list"
        Command::List
      end
    end
  end
end
