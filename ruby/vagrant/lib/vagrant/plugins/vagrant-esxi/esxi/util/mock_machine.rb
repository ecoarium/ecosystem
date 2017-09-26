require 'log4r'
require 'pathname'
require 'tempfile'
require 'fake'

module VagrantPlugins
  module ESXi
    module Util
      class MockMachine
        
        def communicate
          return @communicate unless @communicate.nil?

          @communicate = Vagrant.plugin('2').manager.communicators[:ssh].new(self)

          @communicate.instance_variable_set(:@logger, ::Fake.new)

          @communicate
        end

        def ssh_info
          return @ssh_info unless @ssh_info.nil?
          
          provider_config = ::VagrantPlugins::ESXi::Config.instance
          
          @ssh_info = {
            :host => provider_config.host,
            :port => '22',
            :username => provider_config.user,
            :private_key_path => [provider_config.ssh_key_path]
          }
        end

        def config
          return @config unless @config.nil?

          @config = Class.new{
            def ssh
              return @ssh unless @ssh.nil?
          
              @ssh = Class.new{
                def shell
                  "sh -l"
                end
                def pty
                  false
                end
                def keep_alive
                  true
                end
              }.new
            end
          }.new
        end
      end
    end
  end
end