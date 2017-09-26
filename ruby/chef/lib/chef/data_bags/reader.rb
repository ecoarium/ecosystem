require 'shell-helper'
require 'json'

class Chef
  class DataBag
    module ReaderMethods
      include ShellHelper::Shell

      attr_writer :data_bags_path

      def data_bags_path
        raise "the attribute data_bags_path has not been set, please set this to the path where the data bags can be found." if @data_bags_path.nil?
        raise "the attribute value for data_bags_path does not exist: #{@data_bags_path}" unless File.exist?(@data_bags_path)
        @data_bags_path
      end

      def data_bags
        data_bags = {}

        Dir.glob("#{data_bags_path}/**/*.json"){|data_bag_item_file|
          data_bag_name = File.basename(File.dirname(data_bag_item_file)).to_sym
          data_bags[data_bag_name] = {} if data_bags[data_bag_name].nil?

          data_bag_item_name = File.basename(data_bag_item_file, '.json').to_sym
          data_bags[data_bag_name][data_bag_item_name] = data_bag_item(data_bag_name, data_bag_item_name)
        }

        return data_bags
      end

      def data_bags_items(data_bag_name)
        data_bag = {}

        Dir.glob("#{data_bags_path}/#{data_bag_name}/*.json"){|data_bag_item_file|
          data_bag_item_name = File.basename(data_bag_item_file, '.json')
          data_bag[data_bag_item_name.to_sym] = data_bag_item(data_bag_name, data_bag_item_name)
        }

        return data_bag
      end

      def data_bag_item(data_bag_name, item_name)
        file = "#{data_bags_path}/#{data_bag_name}/#{item_name}.json"
        if !File.exist? file
          raise "can't find data bag item '#{item_name}' in data bag '#{data_bag_name}', looking here:
#{file}"
        end

        data_bag_item = JSON.parse(File.read(file), symbolize_names: true)

        if encrypted?(data_bag_item)
          
          shell_result = shell_command!(
            "knife solo data bag show #{data_bag_name} #{item_name} -s '' -F json -c #{$WORKSPACE_SETTINGS[:ecosystem][:chef][:home]}/knife.rb",
            live_stream: nil,
            environment: {
              'CHEF_DATA_BAGS_HOME' => data_bags_path
            }
          )
          data_bag_item = JSON.parse(shell_result.stdout, symbolize_names: true)
        end
        data_bag_item
      end

      def encrypted?(item)
        evidence = %w{encrypted_data iv version cipher}
        item.any?{|key,value|
          is_it = false
          if value.is_a? Hash
            is_it = value.keys.any?{|key|
              evidence.include?(key.to_s)
            }
          end
          is_it
        }
      end

    end
    class Reader
      include ReaderMethods

      def initialize(data_bags_path)
        @data_bags_path = data_bags_path
      end

    end
  end
end