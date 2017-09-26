require "vagrant"
require 'json'

module VagrantPlugins
  module CommandDNA
    class Show < Vagrant.plugin(2, :command)
      def execute
        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant dna show [machine1] [machine2] [...]"
        end

        argv = parse_options(opts)

        with_target_vms(argv) do |machine|
          chef_config = JSON.parse(machine.config.to_json)["keys"]["vm"]["provisioners"][0]["config"]["json"]

          puts JSON.pretty_generate chef_config
        end

        0
      end
    end
  end
end
