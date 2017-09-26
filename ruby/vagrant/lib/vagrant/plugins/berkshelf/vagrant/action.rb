module Berkshelf
  module Vagrant
    module Action
      autoload :Clean, 'vagrant/plugins/berkshelf/vagrant/action/clean'
      autoload :ConfigureChef, 'vagrant/plugins/berkshelf/vagrant/action/configure_chef'
      autoload :Install, 'vagrant/plugins/berkshelf/vagrant/action/install'
      autoload :List, 'vagrant/plugins/berkshelf/vagrant/action/list'
      autoload :LoadStateFileManager, 'vagrant/plugins/berkshelf/vagrant/action/load-state-file-manager'
      autoload :SetUI, 'vagrant/plugins/berkshelf/vagrant/action/set_ui'
      autoload :Upload, 'vagrant/plugins/berkshelf/vagrant/action/upload'

      class << self
        # Return the Berkshelf install middleware stack. When placed in the action chain
        # this stack will find retrieve and resolve the cookbook dependencies describe
        # in your configured Berksfile.
        #
        # Cookbooks will installed into a temporary directory, called a Shelf, and mounted
        # into the VM. This mounted path will be appended to the chef_solo.cookbooks_path value.
        #
        # @return [::Vagrant::Action::Builder]
        def install
          @install ||= ::Vagrant::Action::Builder.new.tap do |b|
            b.use Berkshelf::Vagrant::Action::Install
          end
        end

        def list
          @list ||= ::Vagrant::Action::Builder.new.tap do |b|
            b.use Berkshelf::Vagrant::Action::List
          end
        end

        # Return the Berkshelf clean middleware stack. When placed in the action chain
        # this stack will clean up any temporary directories or files created by the other
        # middleware stacks.
        #
        # @return [::Vagrant::Action::Builder]
        def clean
          @clean ||= ::Vagrant::Action::Builder.new.tap do |b|
            b.use setup
            b.use Berkshelf::Vagrant::Action::Clean
          end
        end

        def setup
          @setup ||= ::Vagrant::Action::Builder.new.tap do |b|
            b.use ::Vagrant::Action::Builtin::EnvSet, berkshelf: Berkshelf::Vagrant::Env.new
            b.use Berkshelf::Vagrant::Action::SetUI
            b.use Berkshelf::Vagrant::Action::LoadStateFileManager
            b.use Berkshelf::Vagrant::Action::ConfigureChef
          end
        end
      end
    end
  end
end
