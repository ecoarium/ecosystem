require 'pathname'
require 'logging-helper'
require 'plugin/registrar'

module Vagrant
  module Project
    extend LoggingHelper::LogToTerminal

    class << self

      def vagrant_file_path
        ENV['VAGRANT_VAGRANTFILE']
      end

      def root_dir
        @root_dir = $WORKSPACE_SETTINGS[:paths][:project][:home] if @root_dir.nil?
        @root_dir
      end

      def provider_name
        return ENV['VAGRANT_DEFAULT_PROVIDER']
      end

      def vagrant_api_version
        @vagrant_api_version = "2" if @vagrant_api_version.nil?
        @vagrant_api_version
      end

      def vagrant_api_version=(value)
        @vagrant_api_version = value
      end

      def configure(env_symbol, &block)
        Dir.glob(File.expand_path("patches/late/**/*.rb", File.dirname(__FILE__))).each{|patch|
          require patch
        }

				require 'vagrant/project/environment/base'
				require 'vagrant/project/machine/base'

        create_project_environment(env_symbol)

        Vagrant.configure(vagrant_api_version) do |env|
          
          @vagrant_env = env
          @vagrant_env.instance_eval{
            def root_dir
              @root_dir
            end
            def vagrant_file_path
              @vagrant_file_path
            end
            def provider_name
              @provider_name
            end
            def provider_class
              @provider_class
            end
          }

          project_environment.vagrant_env = env
          project_environment.root_dir = root_dir
          project_environment.vagrant_file_path = vagrant_file_path
          project_environment.provider_name = provider_name
          project_environment.provider_class = provider_class

          @vagrant_env.instance_variable_set(:@root_dir, root_dir)
          @vagrant_env.instance_variable_set(:@vagrant_file_path, vagrant_file_path)
          @vagrant_env.instance_variable_set(:@provider_name, provider_name)
          @vagrant_env.instance_variable_set(:@provider_class, provider_class)

          project_environment.instance_exec(@vagrant_env, &block)
        end
      end

      def create_project_environment(env_symbol)
        project_environment_class = ::Plugin::Registrar::Registry.lookup(:environment, env_symbol)
        @project_environment = project_environment_class.new
      end

      def project_environment
        @project_environment
      end

      def project_environment=(value)
        @project_environment = value
      end

      def provider_class=(value)
        @provider_class = value
      end

      def provider_class
        return @provider_class unless @provider_class.nil?
        raise "you must call configure first" if @vagrant_env.nil?
        
        require "vagrant/project/provider/#{provider_name}"
        @provider_class
      ensure
        error "vagrant/project/provider/#{provider_name} did not set the provider_class attribute on Vagrant::Project!" if @provider_class.nil?
      end

    end
  end
end
