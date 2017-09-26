
require 'deep_merge'
require 'json'
require 'fake'

loaded_vagrant_gem_path = Gem::Specification.find_by_name('vagrant').gem_dir

require "#{loaded_vagrant_gem_path}/plugins/provisioners/chef/provisioner/chef_solo.rb"
require "#{loaded_vagrant_gem_path}/plugins/provisioners/chef/config/chef_solo.rb"

module VagrantPlugins
  module Chef

    module Config
      class ChefSolo < BaseRunner

        def data_bags_lock=(value)
          @data_bags_lock = value
        end
        def data_bags_lock
          @data_bags_lock = false if @data_bags_lock.nil?
          @data_bags_lock
        end

        def data_bags_path
          []
        end

        def data_bags_path=(value)
          lock = false

          if value.is_a? Array
            lock = value[1]
            value = value[0]
          end

          if self.data_bags_lock
            return
          end

          data_bags = {}
          Dir.glob("#{value}/*/*.json") {|file|
            bag_name = File.basename(File.dirname(file))
            data_bag_item = JSON.parse(File.read(file),:symbolize_names => true)
            data_bags[bag_name.to_sym] = {} if data_bags[bag_name.to_sym].nil?
            item_name = data_bag_item.delete(:id)
            data_bags[bag_name.to_sym][item_name] = data_bag_item
          }
          self.json = {} if self.json.nil?
          self.json[:data_bags] = {} if self.json[:data_bags].nil?
          self.json[:data_bags].deep_merge!(data_bags)

          self.data_bags_lock = lock

          return
        end

        def merge(other)
          super.tap do |result|
            if @data_bags_lock or other.data_bags_lock
              result.instance_variable_set(:@data_bags_lock, true)
            end

            if @data_bags_lock
              other.json[:data_bags] = @json[:data_bags]
            elsif other.data_bags_lock
              @json[:data_bags] = other.json[:data_bags]
            end

            result.instance_variable_set(:@json, @json.deep_merge(other.json))
            result.instance_variable_set(:@run_list, (@run_list + other.run_list))
          end
        end

      end
    end

    module Provisioner
      class ChefSolo

        # Shares the given folders with the given prefix. The folders should
        # be of the structure resulting from the `expanded_folders` function.
        def share_folders(root_config, prefix, folders, existing=nil)
          existing_set = Set.new
          (existing || []).each do |_, fs|
            fs.each do |id, data|
              existing_set.add(data[:guestpath]) unless data[:guestpath].start_with?('/tmp/vagrant-chef')
            end
          end

          folders.each do |type, local_path, remote_path|
            next if type != :host

            # If this folder already exists, then we don't share it, it means
            # it was already put down on disk.
            if existing_set.include?(remote_path)
              @logger.debug("Not sharing #{local_path}, exists as #{remote_path}")
              next
            end

            opts = {}
            opts[:id] = "v-#{prefix}-#{self.class.get_and_update_counter(:shared_folder)}"
            opts[:type] = @config.synced_folder_type if @config.synced_folder_type

            root_config.vm.synced_folder(local_path, remote_path, opts)
          end

          @shared_folders += folders
        end

        def run_chef_solo
          communicator_logger = nil
          if !ENV['VAGRANT_LOG'].nil? and ENV['VAGRANT_LOG'].upcase == 'DEBUG'
            communicator_logger = @machine.communicate.instance_variable_get(:@logger)
            @machine.communicate.instance_variable_set(:@logger, Fake.new)
          end

          if @config.run_list && @config.run_list.empty?
            @machine.ui.warn(I18n.t("vagrant.chef_run_list_empty"))
          end

          if @machine.guest.capability?(:wait_for_reboot)
            @machine.guest.capability(:wait_for_reboot)
          end

          command = CommandBuilder.command(:solo, @config,
            windows: windows?,
            colored: @machine.env.ui.color?,
          )

          @config.attempts.times do |attempt|
            if attempt == 0
              @machine.ui.info I18n.t("vagrant.provisioners.chef.running_solo")
            else
              @machine.ui.info I18n.t("vagrant.provisioners.chef.running_solo_again")
            end

            opts = { error_check: false, elevated: true }
            exit_status = @machine.communicate.sudo(command, opts) do |type, data|
              # Output the data with the proper color based on the stream.
              color = type == :stdout ? :green : :red

              data = data.chomp
              next if data.empty?

              @machine.ui.info(data, color: color)
            end

            # There is no need to run Chef again if it converges
            return if exit_status == 0
          end

          # If we reached this point then Chef never converged! Error.
          raise ChefError, :no_convergence

          if !ENV['VAGRANT_LOG'].nil? and ENV['VAGRANT_LOG'].upcase == 'DEBUG'
            @machine.communicate.instance_variable_set(:@logger, communicator_logger)
          end
        end

      end

    end

  end
end
