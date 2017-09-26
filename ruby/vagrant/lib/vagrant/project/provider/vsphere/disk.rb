require 'vagrant/project/mixins/configurable'

module Vagrant
  module Project
    module Provider
      class VSphere < Base
        module Config
          class Disk
            include Vagrant::Project::Mixins::Configurable
            include LoggingHelper::LogToTerminal

            attr_config :size, :controller_id, :port

            def configure_this(vagrant_machine, vsphere)
              vsphere.disk size: size, controller_id: controller_id, port: port
            end
          end
        end
      end
    end
  end
end

__END__

https://github.com/rlane/rbvmomi/blob/5dc0ca33165519a83f4eb8765835ac8f17306f84/examples/create_vm.#!/usr/bin/env ruby -wKU
http://apt-browse.org/browse/ubuntu/trusty/universe/all/ruby-fog/1.19.0-1/file/usr/lib/ruby/vendor_ruby/fog/vsphere/requests/compute/create_vm.rb