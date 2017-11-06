loaded_vagrant_gem_path = Gem::Specification.find_by_name('vagrant').gem_dir
require "#{loaded_vagrant_gem_path}/plugins/providers/virtualbox/driver/meta"

module VagrantPlugins
  module ProviderVirtualBox
    module Driver
      class Meta

        def initialize(uuid=nil)
          # Setup the base
          super()

          @logger = Log4r::Logger.new("vagrant::provider::virtualbox::meta")
          @uuid = uuid

          @@version_lock.synchronize do
            if !@@version
              # Read and assign the version of VirtualBox we know which
              # specific driver to instantiate.
              begin
                @@version = read_version
              rescue Vagrant::Errors::CommandUnavailable,
                Vagrant::Errors::CommandUnavailableWindows
                # This means that VirtualBox was not found, so we raise this
                # error here.
                raise Vagrant::Errors::VirtualBoxNotDetected
              end
            end
          end

          # Instantiate the proper version driver for VirtualBox
          @logger.debug("Finding driver for VirtualBox version: #{@@version}")
          driver_map   = {
            "4.0" => Version_4_0,
            "4.1" => Version_4_1,
            "4.2" => Version_4_2,
            "4.3" => Version_4_3,
            "5.0" => Version_5_0,
            "5.1" => Version_5_0,
          }

          if @@version.start_with?("4.2.14")
            # VirtualBox 4.2.14 just doesn't work with Vagrant, so show error
            raise Vagrant::Errors::VirtualBoxBrokenVersion040214
          end

          driver_klass = nil
          driver_map.each do |key, klass|
            if @@version.start_with?(key)
              driver_klass = klass
              break
            end
          end

          if !driver_klass
            supported_versions = driver_map.keys.sort.join(", ")
            raise Vagrant::Errors::VirtualBoxInvalidVersion,
              supported_versions: supported_versions
          end

          @logger.info("Using VirtualBox driver: #{driver_klass}")
          @driver = driver_klass.new(@uuid)
          @version = @@version

          if @uuid
            # Verify the VM exists, and if it doesn't, then don't worry
            # about it (mark the UUID as nil)
            raise VMNotFound if !@driver.vm_exists?(@uuid)
          end
        end
      end
    end
  end
end
