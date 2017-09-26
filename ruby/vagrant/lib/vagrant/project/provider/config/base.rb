require 'vagrant/project/mixins/configurable'
require 'vagrant/project/provider/config/synced_folder'

module Vagrant
  module Project
    module Provider
      module Config
        class Base
          include Vagrant::Project::Mixins::Configurable

          attr_config :synced_folders, class: Vagrant::Project::Provider::Config::SyncedFolder, is_array: true
          attr_config :provider_symbol, :os_name, :os_version

          def initialize
            excluded_configurations << :@vagrant_machine
          end

          attr_config :vagrant_machine

          def box_from_nexus(artifact_name, artifact_version)
            return if provider_symbol == :aws
            box_name = "#{artifact_name}-#{artifact_version}"
            file_name = "#{box_name}.box"

            box_url [
              $WORKSPACE_SETTINGS[:nexus][:direct_base_path],
              $WORKSPACE_SETTINGS[:nexus][:repos][:file],
              'com/vagrantup/basebox',
              artifact_name.gsub(/-/, '/'),
              provider_symbol.to_s,
              artifact_name,
              artifact_version,
              file_name
            ].join('/')
            box box_name
          end

          def box(value=nil)
            unless value.nil?
              @box = value
              vagrant_machine.vm.box = value
            end
            @box
          end

          def box_url(value=nil)
            unless value.nil?
              @box_url = value
              vagrant_machine.vm.box_url = value
            end
            @box_url
          end

        end
      end
    end
  end
end
