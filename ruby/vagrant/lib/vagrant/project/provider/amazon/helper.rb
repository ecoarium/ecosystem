require 'pp'
require 'fog'
require 'macaddr'
require 'yaml'
require 'logging-helper'

module Vagrant
  module Project
    module Provider
      module Amazon
        class Helper
          extend LoggingHelper::LogToTerminal

          class << self

            def region=(value)
              @region = value
            end
            def region
              @region
            end

            def availability_zone=(value)
              @availability_zone = value
            end
            def availability_zone
              @availability_zone
            end

            def aws_client
              Fog::Compute.new(
                {
                  provider: :aws,
                  aws_access_key_id: get_aws_credential['aws_access_key_id'],
                  aws_secret_access_key: get_aws_credential['aws_secret_access_key'],
                  region: region
                }
              )
            end

            def provisioning?
              run_chef = %w{provision up --provision}
              unless ARGV.include?("up") && ARGV.include?("--no-provision")
                if ARGV.any? { |arg| run_chef.include?(arg) }
                  return true
                end
              end
              return false
            end

            def ec2_private_ip(vagrant_machine)
              @ec2_private_ip = {} if @ec2_private_ip.nil?
              return @ec2_private_ip[vagrant_machine.name] unless @ec2_private_ip[vagrant_machine.name].nil?

              unless ec2_instance(vagrant_machine).nil?
                @ec2_private_ip[vagrant_machine.name] = ec2_instance(vagrant_machine).private_ip_address
              else
                return "#{vagrant_machine.name}:ip_address"
              end

              @ec2_private_ip[vagrant_machine.name]
            end

            def ec2_public_ip(vagrant_machine)
              @ec2_public_ip = {} if @ec2_public_ip.nil?
              return @ec2_public_ip[vagrant_machine.name] unless @ec2_public_ip[vagrant_machine.name].nil?

              unless ec2_instance(vagrant_machine).nil?
                @ec2_public_ip[vagrant_machine.name] = ec2_instance(vagrant_machine).public_ip_address
              else
                return "#{vagrant_machine.name}:ip_address"
              end

              @ec2_public_ip[vagrant_machine.name]
            end

            def ec2_instance(vagrant_machine)
              @instance = {} if @instance.nil?
              return @instance[vagrant_machine.name] unless @instance[vagrant_machine.name].nil?

              if File.exist?(vagrant_machine.id_file)
                id = IO.read(vagrant_machine.id_file)

                begin
                  @instance[vagrant_machine.name] = aws_client.servers.get(id)
                rescue  NoMethodError => err
                  File.delete(vagrant_machine.id_file)
                  raise %/
                  **************************************************************************************
                  The id provided does not exist in AWS.  Removing vagrant id file:
                  #{vagrant_machine.id_file}

                  NoMethodError: #{err}
                  **************************************************************************************
                  /
                end
              end

              if provisioning? and @instance[vagrant_machine.name].nil?
                raise "as we are provisioning #{vagrant_machine.name}'s' machine instance should already exist and it does not!"
              end

              @instance[vagrant_machine.name]
            end

            def get_aws_credential
              return @aws_credentials unless @aws_credentials.nil?
              config_file = ENV.has_key?("FOG_RC") ? ENV['FOG_RC'] : "#{ENV['HOME']}/.fog"
              unless File.exist?(config_file)
                raise %/
                  Couldn't find .fog file, environment variable FOG_RC exists? -> #{ENV.has_key?("FOG_RC").inspect}
                  looked for .fog file in: #{config_file}

                  Put your credentials in the .fog file as follows:

                  default:
                      aws_access_key_id: YOUR_ACCESS_KEY_ID
                      aws_secret_access_key: YOUR_SECRET_ACCESS_KEY
                /
              end

              fog_credentials = YAML.load(File.read(config_file))

              unless fog_credentials["default"] and fog_credentials["default"]["aws_access_key_id"] and fog_credentials["default"]["aws_secret_access_key"]
                raise %/
                  deserialized file content:
                  #{fog_credentials.pretty_inspect}

                  #{config_file} is formatted incorrectly.  Please use the following format:

                  default:
                      aws_access_key_id: YOUR_ACCESS_KEY_ID
                      aws_secret_access_key: YOUR_SECRET_ACCESS_KEY
                /
              end

              @aws_credentials = fog_credentials["default"]
              @aws_credentials
            end

            def ssh_key_name(vagrant_machine)
              @ssh_key_name = {} if @ssh_key_name.nil?
              return @ssh_key_name[vagrant_machine.name] unless @ssh_key_name[vagrant_machine.name].nil?

              if File.exist?(vagrant_machine.id_file)
                @ssh_key_name[vagrant_machine.name] = ec2_instance(vagrant_machine).key_name
              else
                key = nil
                keys = ssh_keys
                if keys.empty?
                  key = create_ssh_key
                end

                if key.nil?
                  key_pairs = aws_client.key_pairs
                  key = key_pairs.find { |potential_key| keys.include? potential_key.name }
                  if key.nil?
                    key = create_ssh_key
                  end
                end
                 @ssh_key_name[vagrant_machine.name] = key.name
              end

              @ssh_key_name[vagrant_machine.name]
            end

            def ssh_key_file_path(vagrant_machine)
              @ssh_key_file_path = {} if @ssh_key_file_path.nil?
              @ssh_key_file_path[vagrant_machine.name] = local_key_path(ssh_key_name(vagrant_machine)) if @ssh_key_file_path[vagrant_machine.name].nil?
              @ssh_key_file_path[vagrant_machine.name]
            end

            def windows_password(vagrant_machine)
              response = aws_client.get_password_data(vagrant_machine.id)
              password_data = response.body['passwordData']

              if password_data
                password_data_bytes = Base64.decode64(password_data)
                private_key_path = ssh_key_file_path(vagrant_machine)
                rsa = OpenSSL::PKey::RSA.new File.read(private_key_path)

                debug "Decrypting password data using #{private_key_path}"
                vagrant_machine.config.winrm.password = rsa.private_decrypt(password_data_bytes)
                debug "Successfully decrypted password data using #{private_key_path}"
              end

            end

            def convert_security_group_names_to_ids(security_groups_names, subnet_id)
              debug{"convert_security_group_names_to_ids(#{security_groups_names.inspect}, #{subnet_id.inspect})"}

              subnets = aws_client.describe_subnets('subnet-id' => subnet_id)
              subnet_vpc_id = subnets.body['subnetSet'].first['vpcId']
              security_groups = aws_client.describe_security_groups('vpc-id' => subnet_vpc_id)

              track_security_groups_names = security_groups_names.map(&:clone)

              security_group_ids = security_groups.body['securityGroupInfo'].collect{|security_group|
                if security_groups_names.include?(security_group['groupName'])
                  track_security_groups_names.delete(security_group['groupName'])
                  security_group['groupId']
                end
              }.compact

              raise "not able to find the following security groups:
  * #{track_security_groups_names.join("\n  * ")}

these are the availabile security groups:
  * #{security_groups.body['securityGroupInfo'].collect{|security_group|security_group['groupName']}.join("\n  * ")}
" unless track_security_groups_names.empty?

              security_group_ids
            end

            private

            def create_ssh_key
              key = aws_client.key_pairs.create(:name => "vagrantaws_#{Mac.addr.gsub(':', '').gsub('-', '')}")
              File.open(local_key_path(key.name), File::WRONLY | File::TRUNC | File::CREAT, 0600) { |f| f.write(key.private_key) }
              return key
            end

            def local_key_path(key_name)
              path = ssh_keys_path
              File.expand_path(key_name, path)
            end

            def ssh_keys_path
              return @ssh_keys_path unless @ssh_keys_path.nil?
              @ssh_keys_path = File.expand_path("aws/keys", ENV["VAGRANT_HOME"] || "~/.vagrant.d")
              FileUtils.mkdir_p(@ssh_keys_path) unless File.exist? @ssh_keys_path
              @ssh_keys_path
            end

            def ssh_keys
              Dir.chdir(ssh_keys_path) { |unused| Dir.entries('.').select { |f| File.file?(f) } }
            end
          end
        end
      end
    end
  end
end
