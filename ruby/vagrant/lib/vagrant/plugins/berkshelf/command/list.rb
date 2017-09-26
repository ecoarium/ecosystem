require "vagrant"
require 'logging-helper'
require 'pp'

module Berkshelf
  module Vagrant
    module Command
      class List < ::Vagrant.plugin(2, :command)
        include LoggingHelper::LogToTerminal
        
        def execute
          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant berks-ls [machine1] [machine2] [...]"
          end

          argv = parse_options(opts)

          with_target_vms(argv) do |machine|

            action = ::Vagrant::Action::Builder.new.tap do |b|
              b.use ::Vagrant::Action::Builtin::EnvSet, berkshelf: Berkshelf::Vagrant::Env.new
              b.use Berkshelf::Vagrant::Action::SetUI
              b.use Berkshelf::Vagrant::Action::LoadStateFileManager
              b.use Berkshelf::Vagrant::Action::ConfigureChef
              b.use Berkshelf::Vagrant::Action::List
            end

            machine.action_raw('berkshelf_list', action)
          end
        end

      end
    end
  end
end
