require "vagrant"

module VagrantPlugins
  module ManagedServers
    class Config < Vagrant.plugin("2", :config)
      
      # The IP address or hostname of the managed server.
      #
      # @return [String]
      attr_accessor :server
      attr_accessor :port
      attr_accessor :user
      attr_accessor :ssh_key_path
      attr_accessor :password

      def initialize()
        @server      = UNSET_VALUE
        @ssh_key_path = File.expand_path('~/.ssh/id_rsa')
        @port = '22'
      end

      def finalize!
        # server must be nil, since we can't default that
        @server = nil if @server == UNSET_VALUE
      end

      def validate(machine)
        errors = _detected_errors
        errors << I18n.t("vagrant_managed_servers.config.server_required") if @server.nil?
        { "ManagedServers Provider" => errors }
        errors << I18n.t("vagrant_managed_servers.config.password_or_private_key_missing") if @ssh_key_path.nil? && @password.nil?
        { "ManagedServers Provider" => errors }
      end
    end
  end
end
