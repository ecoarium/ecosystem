require "vagrant"

module VagrantPlugins
  module Reports
    class Plugin < Vagrant.plugin('2')
      name 'reports'
      description <<-DESC
      This plugin provides various report commands
      DESC

      command "machines" do
        require_relative "command/machines"
        Machines
      end
    end
  end
end
