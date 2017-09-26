
module Vagrant
  module Project
    module Provisioner
      class None

        attr_reader :root_dir, :machine_config

        def initialize(config)
          @root_dir = $WORKSPACE_SETTINGS[:paths][:project][:home]
          @machine_config = config
        end

        def configure(&block)
          block.call() if block_given?
        end

        def set_defaults(&block)
          configure(&block)
        end
      end
    end
  end
end
