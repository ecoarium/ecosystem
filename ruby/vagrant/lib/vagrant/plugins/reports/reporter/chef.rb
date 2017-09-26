require 'logging-helper'
require 'rbconfig'
require 'timeout'
require 'pp'

module VagrantPlugins
  module Reports
    module Reporter
      class Chef
        extend LoggingHelper::LogToTerminal

        class << self

          def generate_report(machine_name, provisioner_info, provider_info)
            report_file = Tempfile.new('chef_report.json')

            begin

              if RbConfig::CONFIG['host_os'].include?('darwin') or RbConfig::CONFIG['host_os'].include?('linux')
                run_forked(machine_name, provisioner_info, provider_info, report_file)
              else
                run_in_process(machine_name, provisioner_info, provider_info, report_file)
              end

            ensure
              report_file.close
              report_file.unlink
            end
          end

          def run_in_process(machine_name, provisioner_info, provider_info, report_file)
            run_chef_mocked(machine_name, provisioner_info, provider_info, report_file)
          end

          def run_forked(machine_name, provisioner_info, provider_info, report_file)
            child_pid = fork do
              run_chef_mocked(machine_name, provisioner_info, provider_info, report_file)

              exit()
            end

            begin
              Timeout.timeout(580) do
                Process.wait(child_pid)

                raise "failed to produce chef report, exit code: #{$?.exitstatus}" unless $?.exitstatus == 0

                JSON.parse(File.read(report_file))
              end
            rescue Timeout::Error
              Process.kill 9, child_pid
              # collect status so it doesn't stick around as zombie process
              Process.wait child_pid
              raise "generation of chef report timeout"
            end
          end

          def run_chef_mocked(machine_name, provisioner_info, provider_info, report_file)
            require 'chefspec'
            require 'chefspec/extensions/chef/data_query'
            require 'chef/config'
            require 'chef/config_fetcher'
            require 'berkshelf/patch/berkshelf'
            require 'vagrant/plugins/berkshelf/vagrant/state-file-manager'
            require 'berkshelf/smart'
            require 'json'

            ::Chef::DSL::DataQuery.module_exec{
              alias_method :search, :old_search
              alias_method :data_bag, :old_data_bag
              alias_method :data_bag_item, :old_data_bag_item
            }

            chef_json_input = provisioner_info['config']['json']

            chef_json_input['run_list'] = provisioner_info['config']['run_list']

            ChefSpec::SoloRunner.class_eval "
              class << self
                @@provisioner_info = '#{JSON.pretty_generate chef_json_input}'
                def provisioner_info
                  @@provisioner_info
                end
              end
            "

            ChefSpec::SoloRunner.class_exec{

              def chef_client_json
                return @chef_client_json unless @chef_client_json.nil?
                @chef_client_json = ::Chef::JSONCompat.from_json(ChefSpec::SoloRunner.provisioner_info)
              end

              def client
                return @client if @client

                @client = ::Chef::Client.new(chef_client_json)

                @client.ohai.data = Mash.from_hash(Fauxhai.mock(options).data)
                @client.load_node
                @client.build_node
                @client.save_updated_node
                @client
              end

              def with_default_options(options)
                cookbook_path = options[:cookbook_path]
                config = RSpec.configuration
                cookbook_path = config.cookbook_path if cookbook_path.nil?
                cookbook_path = calling_cookbook_path(caller) if cookbook_path.nil?

                {
                  cookbook_path: cookbook_path,
                  role_path:     config.role_path || default_role_path,
                  environment_path: config.environment_path || default_environment_path,
                  log_level:     config.log_level,
                  path:          config.path,
                  platform:      config.platform,
                  version:       config.version
                }.merge(options)
              end

              def load_attributes()
                cookbook_loader = ::Chef::CookbookLoader.new(::Chef::Config[:cookbook_path])
                cookbook_loader.load_cookbooks

                cookbook_collection = ::Chef::CookbookCollection.new(cookbook_loader)
                run_context = ::Chef::RunContext.new(node, cookbook_collection, @client.instance_eval('@events'))
                expanded_run_list = @client.expanded_run_list

                run_context.instance_eval {
                  def load_attributes(run_list_expansion)
                    @cookbook_compiler = ::Chef::RunContext::CookbookCompiler.new(self, run_list_expansion, events)
                    @cookbook_compiler.compile
                  end
                }

                run_context.load_attributes(expanded_run_list)
              end
            }

            ::Chef::Log.init(MonoLogger.new($stdout))

            repo_cookbooks_path = $WORKSPACE_SETTINGS[:paths][:project][:deploy][:chef][:cookbook][:home]

            state_file_manager = Berkshelf::Vagrant::StateFileManager.new(machine_name.to_s)
            berks_cookbooks_path = state_file_manager.shelf_directory_path

            if provider_info["os_name"] == 'windows'
              ENV['WINDIR'] = 'C:\Windows'
            end

            chef_run = ChefSpec::SoloRunner.new(log_level: :debug, platform: provider_info["os_name"], version: provider_info["os_version"], cookbook_path: [repo_cookbooks_path, berks_cookbooks_path])

            baseline = chef_run.node.to_hash.keys
            chef_run.chef_client_json.to_hash.keys.each{|key|
              baseline.delete(key)
            }
            baseline << 'run_list'

            chef_run.load_attributes()

            report = {}

            chef_run.node.to_hash.keys.each { |node_name|
              unless baseline.include? node_name
                report[node_name] = chef_run.node[node_name]
              end
            }

            report_file.binmode
            report_file.write(JSON.pretty_generate(report.to_hash))
            report_file.fsync
            report_file.close
          end
        end
      end
    end
  end
end
