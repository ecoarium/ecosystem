require "vagrant"

module VagrantPlugins
  module CommandDNA
    class Plugin < Vagrant.plugin('2')
      name "command dna"
      description <<-DESC
      This plugin allows the user to view and validate chef configuration
      DESC

      command("dna") do
        require_relative "command/root"
        Command::Root
      end
    end
  end
end
