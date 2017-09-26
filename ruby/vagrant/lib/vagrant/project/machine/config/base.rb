require "vagrant/project/mixins/configurable"
require "vagrant/project/mixins/data_bags"

module Vagrant
  module Project
    module Machine
      module Config
        class Base
          include Vagrant::Project::Mixins::Configurable
          include Vagrant::Project::Mixins::DataBags

          attr_config :dependencies, is_array: true

          attr_config :provider, :vagrant_machine, :machine

          def machines
            Vagrant::Project.project_environment.machines
          end

          def provisioner(value=nil, &block)
          	@provisioner = value unless value.nil?
          	@provisioner.configure(&block)
          	return nil
          end

        end
      end
    end
  end
end
