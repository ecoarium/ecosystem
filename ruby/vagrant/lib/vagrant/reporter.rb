require 'logging-helper'
require 'facets/module/cattr'
require 'vagrant/shell'
require 'json'

module Vagrant
  class Reporter
    extend Vagrant::Shell
    extend LoggingHelper::LogToTerminal
    class << self

      cattr_reader :report_path, :machine_report

      @@report_path = nil
      @@machine_report = nil

      def report_path
        @@report_path = "#{vagrant_state_dir}/report.json" if @@report_path.nil?
        @@report_path
      end

      def machine_report
        if ENV['CREATE_MACHINE_REPORT'] == 'false'
          if File.exist? report_path
            return @@machine_report unless @@machine_report.nil?
            read_report
            return @@machine_report
          else
            return return_no_machine_report
          end
        end

        return @@machine_report unless @@machine_report.nil?

        unless File.exist?(vagrant_file)
          return handle_nonexistant_vagrant_file
        end

        cookbook_name = $WORKSPACE_SETTINGS[:project][:name].gsub(/-/, '_')
        dist_artifacts_path = Regexp.escape("#{$WORKSPACE_SETTINGS[:paths][:project][:deploy][:chef][:cookbook][:home]}/#{cookbook_name}/files/default/dist-file/")
        if current?(report_path, [vagrant_file, vagrant_lib_path, cookbooks_path], [{pattern: /#{dist_artifacts_path}.*/}])
          read_report
        else
          generate
        end

        @@machine_report
      end

      def regenerate_machine_report
        generate

        @@machine_report
      end

      private

      def handle_nonexistant_vagrant_file
        warn %/

#{divider}

The vagrant context folder does not contain a Vagrantfile.
#{vagrant_file}

This may be okay. For example:
  *  If you are working in a test context and have not yet pulled the cache, this is to be expected.

#{divider}

/
        return_no_machine_report
      end

      def return_no_machine_report
        $WORKSPACE_SETTINGS[:machine_report] = {}
      end

      def generate
        raw_vagrant_execution("machines", {live_stream: nil, quiet: false})
        read_report
      end

      def read_report
        raise %/
the machine report file does not exist:
#{report_path}
        / unless File.exist? report_path
        @@machine_report = JSON.parse(File.read(report_path),:symbolize_names => true)
        update_global
      end

      def update_global
        $WORKSPACE_SETTINGS[:machine_report] = {} if $WORKSPACE_SETTINGS[:machine_report].nil?

        $WORKSPACE_SETTINGS[:machine_report] = machine_report
      end
    end
  end
end
