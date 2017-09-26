require 'logging-helper'
require 'pp'

module Berkshelf
  module Vagrant
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Config < ::Vagrant.plugin("2", :config)
      class << self
        attr_accessor :instance
      end

      include LoggingHelper::LogToTerminal

      def url=(value)
        raise "I thought this was cruft so I deleted: attr_accessor :url"
      end

      def url
        raise "I thought this was cruft so I deleted: attr_accessor :url"
      end

      # @return [String]
      #   path to the Berksfile to use with Vagrant
      attr_reader :berksfile_path

      # @return [Array<Symbol>]
      #   only cookbooks in these groups will be installed and copied to
      #   Vagrant's shelf
      attr_accessor :only

      # @return [Array<Symbol>]
      #   cookbooks in all other groups except for these will be installed
      #   and copied to Vagrant's shelf
      attr_accessor :except

      # @return [String]
      #   the Chef node name (client name) to use to authenticate with the remote
      #   chef server to upload cookbooks when using the chef client provisioner
      attr_accessor :node_name

      # @return [String]
      #   a filepath to a chef client key to use to authenticate with the remote
      #   chef server to upload cookbooks when using the chef client provisioner
      attr_accessor :client_key

      def initialize
        super

        @except         = Array.new
        @only           = Array.new
        @node_name      = Berkshelf::Config.instance.chef.node_name
        @client_key     = Berkshelf::Config.instance.chef.client_key
      end

      def enabled
        is_enabled = !berksfile_path.nil? and File.exist?(berksfile_path)
        is_enabled
      end 

      # @param [String] value
      def berksfile_path=(value)
        if value.nil?
          @berksfile_path = nil
        else
          @berksfile_path = File.expand_path(value)
        end
        @berksfile_path
      end

      # @param [String] value
      def client_key=(value)
        @client_key = File.expand_path(value)
      end

      alias_method :to_hash, :instance_variables_hash

      def validate(machine)
        errors = Array.new

        unless [TrueClass, FalseClass].include?(enabled.class)
          errors << "A value for berkshelf.enabled can be true or false."
        end

        if enabled
          if machine.config.berkshelf.berksfile_path.nil?
            errors << "berkshelf.berksfile_path cannot be nil."
          end

          unless File.exist?(machine.config.berkshelf.berksfile_path)
            errors << "No Berksfile was found at #{machine.config.berkshelf.berksfile_path}."
          end

          if !except.empty? && !only.empty?
            errors << "A value for berkshelf.empty and berkshelf.only cannot both be defined."
          end
        end

        { "berkshelf configuration" => errors }
      end
    end
  end
end
