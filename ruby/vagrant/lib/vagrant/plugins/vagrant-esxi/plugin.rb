$:.push File.dirname(__FILE__)
require 'vagrant-esxi'
require "vagrant"

module VagrantPlugins
  module ESXi
    class Plugin < Vagrant.plugin("2")
      name "esxi"
      description "Allows Vagrant to manage machines with VMWare esxi"

      config(:esxi, :provider) do
        require_relative "esxi/config"
        Config
      end

      provider(:esxi) do
        # TODO: add logging
        setup_i18n

        # Return the provider
        require 'esxi/provider'
        Provider
      end

      def self.setup_i18n
        I18n.load_path << File.expand_path("locales/en.yml", ESXi.source_root)
        I18n.reload!
      end
    end
  end
end
