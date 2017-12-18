require 'vagrant/project/mixins/configurable'
require 'vagrant/project/provider/config/synced_folder'

module Vagrant
  module Project
    module Provider
      module Config
        class Base
          include Vagrant::Project::Mixins::Configurable
          include LoggingHelper::LogToTerminal

          attr_config :synced_folders, class: Vagrant::Project::Provider::Config::SyncedFolder, is_array: true
          attr_config :provider_symbol, :os_name, :os_version

          def initialize
            excluded_configurations << :@vagrant_machine
          end

          attr_config :vagrant_machine

          def box_from_packer(packer_box_name, packer_box_version)
            debug {"all boxes:\n#{$WORKSPACE_SETTINGS[:packer][:boxes].pretty_inspect}"}
            box_info = $WORKSPACE_SETTINGS[:packer][:boxes][provider_symbol][packer_box_name.to_sym][packer_box_version.to_sym]
            debug {"box_info:\n#{box_info.pretty_inspect}"}

            box "#{packer_box_name}-#{packer_box_version}".gsub(/\//, '-')
            box_url box_info[:url]
            os_name box_info[:os_name]
            os_version box_info[:os_version]
          end

          def box_from_nexus(artifact_name, artifact_version)
            box_name = "#{artifact_name}-#{artifact_version}".gsub(/\//, '-')
            file_name = "#{box_name}.box"

            box_url [
              $WORKSPACE_SETTINGS[:nexus][:direct_base_path],
              $WORKSPACE_SETTINGS[:nexus][:repos][:file],
              'com/vagrantup/basebox',
              artifact_name,
              provider_symbol.to_s,
              artifact_name.gsub(/\//, '-'),
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
