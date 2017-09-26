require 'fileutils'
require 'json'

module Vagrant
  module Project
    module Mixins
      module DataBags

      	def get_data_bag(bag_name, path=$WORKSPACE_SETTINGS[:paths][:project][:deploy][:chef][:data][:bags][:home])
          data_bag = {}

          Dir.glob("#{path}/#{bag_name}/*.json"){|data_bag_item_file|
            data_bag_item_name = File.basename(data_bag_item_file, '.json')
            data_bag[data_bag_item_name.to_sym] = JSON.parse(File.read(data_bag_item_file), symbolize_names: true)
          }

          return data_bag
        end

        def get_data_bag_item(bag_name, item_name, path=$WORKSPACE_SETTINGS[:paths][:project][:deploy][:chef][:data][:bags][:home])
          file = "#{path}/#{bag_name}/#{item_name}.json"
          if !File.exists? file
            raise "can't find data bag item #{bag_name} #{item_name}, looking here: #{file}"
          end

          JSON.parse(File.read(file), symbolize_names: true)
        end

        def local_env_data_bags_path
          "#{$WORKSPACE_SETTINGS[:paths][:project][:deploy][:vagrant][:state]}/data_bags"
        end

        def local_env_overriden_data_bags_path
          "#{$WORKSPACE_SETTINGS[:paths][:project][:deploy][:vagrant][:context][:home]}/data_bag_overrides"
        end

        def local_env_data_bags_uptodate?
          return false unless File.exist?(local_env_data_bags_path)

          data_bag_files = Dir.glob("#{$WORKSPACE_SETTINGS[:paths][:project][:deploy][:chef][:data][:bags][:home]}/**/*")
          real_data_bags_uptodate = FileUtils.uptodate?(local_env_data_bags_path, data_bag_files)

          overriden_data_bag_files = Dir.glob("#{local_env_overriden_data_bags_path}/**/*")
          overrides_data_bags_uptodate = FileUtils.uptodate?(local_env_data_bags_path, overriden_data_bag_files)

          (real_data_bags_uptodate and overrides_data_bags_uptodate)
        end

        def merge_data_bags
          FileUtils.mkdir_p $WORKSPACE_SETTINGS[:paths][:project][:deploy][:vagrant][:state] unless File.exist?($WORKSPACE_SETTINGS[:paths][:project][:deploy][:vagrant][:state])
          FileUtils.rm_rf local_env_data_bags_path if File.exist? local_env_data_bags_path

          FileUtils.cp_r "#{$WORKSPACE_SETTINGS[:paths][:project][:deploy][:chef][:data][:bags][:home]}/", $WORKSPACE_SETTINGS[:paths][:project][:deploy][:vagrant][:state]
          FileUtils.cp_r "#{local_env_overriden_data_bags_path}/.", local_env_data_bags_path
        end

      end
    end
  end
end
