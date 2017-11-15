require "vagrant"

Dir.glob(File.expand_path("../reporter/**/*.rb", File.dirname(__FILE__))).each{|reporter|
  require reporter
}

require 'json'
require 'deep_merge'
require 'logging-helper'
require 'pp'


module VagrantPlugins
  module Reports
    class Machines < Vagrant.plugin(2, :command)
      include LoggingHelper::LogToTerminal

      def execute
        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant machines [machine1] [machine2] [...]"
        end

        argv = parse_options(opts)

        report = {}
        with_target_vms(argv) do |machine|
          debug {"building report for machine: #{machine.name}"}

          action = ::Vagrant::Action::Builder.new.tap do |b|
            b.use ::Vagrant::Action::Builtin::EnvSet, berkshelf: Berkshelf::Vagrant::Env.new
            b.use Berkshelf::Vagrant::Action::SetUI
            b.use Berkshelf::Vagrant::Action::LoadStateFileManager
            b.use Berkshelf::Vagrant::Action::ConfigureChef
            b.use Berkshelf::Vagrant::Action::Install
          end

          machine.action_raw('berkshelf_install', action)

          break if Vagrant::Project.project_environment.nil? or Vagrant::Project.project_environment.machines.nil? or Vagrant::Project.project_environment.machines.empty?
          project_machine = Vagrant::Project.project_environment.machines[machine.name]

          box = nil
          unless machine.box.nil?
            box = machine.box.deep_to_hash
          end

          report[machine.name] = {
            ssh_info: machine.ssh_info,
            box: box,
            data_dir: machine.data_dir.deep_to_hash,
            id: machine.id,
            dependencies: project_machine.configuration.dependencies,
            raw_providers: {},
            communicator: machine.config.vm.communicator,
            guest: machine.config.vm.guest,
            networks: machine.config.vm.networks,
            synced_folders: machine.config.vm.synced_folders
          }

          if machine.config.vm.communicator == :winrm
            VagrantPlugins::CommunicatorWinRM::Helper.winrm_info(machine) unless machine.id.nil?
            report[machine.name][:winrm_info] = machine.config.winrm.deep_to_hash
          end

          provider_reporter_klass = project_machine.provider_class.to_s[/Vagrant::Project(.*)/, 1]

          machine.config.vm.instance_variable_get(:@__providers).keys.each{|providers|
            report[machine.name][:raw_providers][providers] = {} if report[machine.name][:raw_providers][providers].nil?
            report[machine.name][:raw_providers][providers].deep_merge!(machine.config.vm.get_provider_config(providers).deep_to_hash)
          }

          report[machine.name][:provider] = eval "VagrantPlugins::Reports::Reporter#{provider_reporter_klass}.generate_report(machine, project_machine)"

          report[machine.name][:provisioners] = {}
          machine.config.vm.provisioners.each{|provisioner|
            provisioner_name = provisioner.name
            provisioner_name = provisioner.type if provisioner_name.nil?

            report[machine.name][:provisioners][provisioner_name] = provisioner.deep_to_hash

            if report[machine.name][:provisioners][provisioner_name]['type'] == :chef_solo
              chef_attributes = VagrantPlugins::Reports::Reporter::Chef.generate_report(machine.name, report[machine.name][:provisioners][provisioner_name], report[machine.name][:provider])

              report[machine.name][:provisioners][provisioner_name]['config']['json'] = chef_attributes
            end
          }
        end

        debug { report.pretty_inspect }

        json_report = JSON.pretty_generate report
        report_file_path = File.expand_path('.vagrant/report.json')
        File.open(report_file_path,"w") {|file|
          file.write(json_report)
        }
        0
      end

    end
  end
end
