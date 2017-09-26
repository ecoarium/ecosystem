require 'chef/data_bags/reader'

module Resource
  @@gem_name = nil
  def gem_name
    @@gem_name
  end

  def self.included(base)
    class_source_dir = File.dirname(caller[0].split(':')[0])
    gem_folder = class_source_dir[/(.*)\/lib\/.*/, 1]
    @@gem_name = File.basename(gem_folder)
  end

  def resource(name)
    possible_resource_locations = [
      "#{$WORKSPACE_SETTINGS[:paths][:project][:workspace][:settings][:ruby][:home]}/#{gem_name}/resources"
      "#{$WORKSPACE_SETTINGS[:ecosystem][:paths][:ruby][:home]}/#{gem_name}/resources"
    ]

    possible_resource_locations.each{|resource_folder|
      data_bag_reader = Chef::DataBag::Reader.new(File.dirname(resource_folder))
      data_bag_item = data_bag_reader.data_bag_item(File.basename(resource_folder), name) rescue nil
      return data_bag_item unless data_bag_item.nil?
    }

    raise "unable to find the resource #{name} in either of these locations:
  * #{possible_resource_locations.join("\n  * ")}"
  end
end
