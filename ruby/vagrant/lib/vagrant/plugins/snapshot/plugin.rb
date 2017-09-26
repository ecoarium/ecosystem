require "vagrant"
require_relative 'snapshotutil'

module VagrantPlugins
  module CommandSnapshot
    class Plugin < Vagrant.plugin("2")
      name "command snapshot"
      description <<-DESC
      "This plugin provides improved snapshot capability"
      DESC

      command("snapshot") do
      	require_relative "command/root"
        Command::Root
      end
    end
  end
end
