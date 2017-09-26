require "vagrant"

module VagrantPlugins
  module WindowsShell
    class Plugin < Vagrant.plugin('2')
      name 'windows-shell'
      description <<-DESC
      This plugin provides remote shell access to windows machines over winrm
      DESC

      command "win-shell" do
        require_relative "command/remote-shell"
        RemoteShell
      end
    end
  end
end
