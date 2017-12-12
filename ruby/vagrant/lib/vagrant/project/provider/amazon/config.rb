require 'vagrant/project/provider/config/base'
require 'vagrant/project/provider/amazon/network'
require 'vagrant/project/provider/amazon/helper'
require 'vagrant/project/mixins/tagging'

module Vagrant
  module Project
    module Provider
      module Amazon
        class Configuration < Vagrant::Project::Provider::Config::Base
          include LoggingHelper::LogToTerminal
          include Vagrant::Project::Mixins::Tagging

          attr_config :access_key_id, :secret_access_key, :keypair_name, :ssh_username
          attr_config :ami, :instance_type, :region, :subnet_id, :availability_zone, :tags

          attr_config :security_groups, is_array: true
          attr_config :network, class: Vagrant::Project::Provider::Amazon::Config::Network

          def initialize
            @box = 'dummy'
            @box_url = File.expand_path("../../../../../boxes/aws/dummy.box", File.dirname(__FILE__))

            @access_key_id = Helper.get_aws_credential['aws_access_key_id']
            @secret_access_key = Helper.get_aws_credential['aws_secret_access_key']
            @region = 'us-east-1'
            @security_groups = ['default', 'ssh']
            @ssh_username = 'vagrant'

            @instance_type = 'm3.medium'
            @tags = {}
          end

          def box_from_packer(packer_box_name, packer_box_version)
            super

            region_symbol = $WORKSPACE_SETTINGS[:aws][:region].to_sym

            ami $WORKSPACE_SETTINGS[:packer][:boxes][:aws][packer_box_name.to_sym][packer_box_version.to_sym][:ami][region_symbol]

            configure_dummy_box
          end

          def box_from_nexus(artifact_name, artifact_version)
            super

            region_symbol = $WORKSPACE_SETTINGS[:aws][:region].to_sym

            ami $WORKSPACE_SETTINGS[:packer][:boxes][:aws][packer_box_name.to_sym][packer_box_version.to_sym][:ami][region_symbol]

            configure_dummy_box
          end

          def configure_dummy_box
            box 'dummy'
            box_url File.expand_path("../../../../../boxes/aws/dummy.box", File.dirname(__FILE__))
          end

          def configure_this(vagrant_machine, aws)
            unless ssh_username == 'vagrant'
              vagrant_machine.ssh.username = ssh_username
              vagrant_machine.ssh.private_key_path = Vagrant::Project::Provider::Amazon::Helper.ssh_key_file_path(vagrant_machine)
            end

            aws.access_key_id = access_key_id
            aws.secret_access_key = secret_access_key

            aws.region = region
            aws.availability_zone = availability_zone

            Helper.region = region
            Helper.availability_zone = availability_zone

            @keypair_name = Helper.ssh_key_name(vagrant_machine) if @keypair_name.nil?

            aws.keypair_name = keypair_name

            aws.ami = ami
            aws.subnet_id = subnet_id
            aws.security_groups = Helper.convert_security_group_names_to_ids(security_groups, subnet_id) unless subnet_id.nil?
            aws.instance_type = instance_type
            aws.tags = tags
            configure_dummy_box
          end

        end
      end
    end
  end
end
