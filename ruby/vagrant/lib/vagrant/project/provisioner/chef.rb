
module Vagrant
  module Project
    module Provisioner
      class Chef

        attr_reader :root_dir, :machine_config, :chef_version

        def initialize(config)
          @root_dir = $WORKSPACE_SETTINGS[:paths][:project][:home]
          @machine_config = config
        end

        def configure(&block)
        	machine_config.vm.provision("chef_solo_#{machine_config.name}", type: 'chef_solo', &block) if block_given?
        end

        def set_defaults(&block)
          machine_config.berkshelf.berksfile_path = File.expand_path("Berksfile", $WORKSPACE_SETTINGS[:paths][:project][:deploy][:vagrant][:context][:home])

          configure{|chef|
	          chef.cookbooks_path = $WORKSPACE_SETTINGS[:paths][:project][:deploy][:chef][:cookbook][:home]
	          chef.data_bags_path = $WORKSPACE_SETTINGS[:paths][:project][:deploy][:chef][:data][:bags][:home]

	          chef.install = false
	          chef.log_level = :debug
	        }

          configure(&block)
        end
      end
    end
  end
end
