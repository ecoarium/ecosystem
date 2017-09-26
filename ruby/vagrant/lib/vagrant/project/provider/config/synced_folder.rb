require "vagrant/project/mixins/configurable"

module Vagrant
  module Project
    module Provider
			module Config
				class SyncedFolder
					include Vagrant::Project::Mixins::Configurable

					attr_config :host_path, :guest_path, :create, :disabled, :owner, :group, :mount_options, :type

					def configure_this(vagrant_machine, provider)
						options = {}
						configurable_variables.each{|var_name|
			        var = instance_variable_get(var_name.to_s)
			        key_name = var_name.to_s.gsub(/@/, '').to_sym
			        options[key_name] = var unless var.nil?
			      }

						vagrant_machine.vm.synced_folder(
							host_path,
							guest_path,
							options
						)
					end
				end
			end
    end
  end
end