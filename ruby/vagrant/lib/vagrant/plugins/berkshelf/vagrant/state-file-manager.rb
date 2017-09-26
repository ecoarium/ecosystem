require 'logging-helper'
require 'berkshelf'
require 'fileutils'
require 'tmpdir'

module Berkshelf
  module Vagrant
    class StateFileManager
      include LoggingHelper::LogToTerminal

      attr_accessor :state_file_path, :shelf_directory_path, :flag_file_path

      def initialize(machine_name)
        @machine_name = machine_name

        @root_shelf_path = File.join(Berkshelf.berkshelf_path, 'vagrant')
        FileUtils.mkdir_p(root_shelf_path) unless File.exist?(root_shelf_path)

        @state_file_path = File.join(['.vagrant', 'machines', machine_name, 'berkshelf'].compact)
        @flag_file_path = File.join(['.vagrant', 'machines', machine_name, 'berkshelf.flag'].compact)
        @shelf_directory_path = obtain_shelf
      end

      def clean
        FileUtils.remove_dir(shelf_directory_path, force: true) if File.exist? shelf_directory_path
        [
          state_file_path,
          flag_file_path
        ].each{|file_path|
          FileUtils.rm_f(file_path)
        }
      end

      private

      attr_accessor :machine_name, :root_shelf_path

      def obtain_shelf
        shelf = load_shelf

        if shelf.nil?
          shelf = cache_shelf
        end
        shelf
      end

      def cache_shelf()
        shelf = mkshelf

        File.open(state_file_path, 'w+') do |f|
          f.write(shelf)
        end

        shelf
      end

      def load_shelf()
        return nil unless File.exist?(state_file_path)

        File.read(state_file_path).chomp
      end

      def mkshelf()
        if machine_name.nil?
          prefix_suffix = 'berkshelf-'
        else
          prefix_suffix = ['berkshelf-', "-#{machine_name}"]
        end

        Dir.mktmpdir(prefix_suffix, root_shelf_path)
      end
    end
  end
end