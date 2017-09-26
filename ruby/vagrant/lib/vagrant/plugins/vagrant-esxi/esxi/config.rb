require "vagrant"

module VagrantPlugins
  module ESXi
    class Config < Vagrant.plugin("2", :config)
      class << self
        attr_accessor :instance
      end
      attr_accessor :host
      attr_accessor :user
      attr_accessor :ssh_key_path
      attr_accessor :password
      attr_accessor :datastore
      attr_accessor :network
      attr_accessor :customizations
      attr_accessor :disks

      def initialize
        super

        @disks = []
        @customizations = []
        @ssh_key_path = File.expand_path('~/.ssh/id_rsa')
        @network = 'VM-Network'
      end

      def memory=(size)
        raise "memory size must be divisible by 4" unless size.to_i % 4 == 0
        customize('memSize', size)
      end

      def vcpus=(number)
        customize('numvcpus', number)
      end

      def customize(key, value)
        customizations.push({key: key, value: value})
      end

      def disk(size:, controller_id:, port:)
        disks.push({size: size, controller_id: controller_id, port: port})
      end

      def finalize!
        super

        self.class.instance = self
      end

      def validate(machine)
        errors = _detected_errors

        errors << I18n.t("config.host") if host.nil?
        errors << I18n.t("config.user") if user.nil?
        errors << I18n.t("config.password") if password.nil?
        errors << I18n.t("config.datastore") if datastore.nil?

        { "esxi Provider" => errors }
      end
    end
  end
end
