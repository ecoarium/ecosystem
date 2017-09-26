require "vagrant"
require 'json'

module VagrantPlugins
  module CommandDNA
    class Validate < Vagrant.plugin(2, :command)
      def execute
        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant dna [validate] [machine1] [machine2] [...]"
        end

        argv = parse_options(opts)

        # load specified config rules
        rules = Vagrant::Project.project_environment.config_rules
        ignore = flat_hash(rules.ignore || {})
        regex = flat_hash(rules.regex || {})

        congruency = {}

        with_target_vms(argv) do |machine|
          chef_config = JSON.parse(machine.config.to_json)["keys"]["vm"]["provisioners"][0]["config"]["json"]

          flat_config = flat_hash(chef_config)

          flat_config.each do |attribute, value|
            # check if should ignore validation for that attribute
            unless ignore.has_key?(attribute)
              # check for regex match
              if regex.has_key?(attribute)
                unless value =~ regex[attribute]
                  print_attribute_message("FAILURE: Value doesn't match specified regex", machine.name, attribute)
                end
              end

              # warning for nil attributes
              if value.nil?
                print_attribute_message("WARNING: Nil value", machine.name, attribute)
              end

              # warning for same name attributes between different machines with noncongruent values
              # Intended to catch problems such as noncongruent IP definitions
              if congruency[attribute].nil?
                congruency[attribute] = {}
                congruency[attribute][:value] = value
                congruency[attribute][:machine] = machine.name
              elsif congruency[attribute][:value] != value
                print_attribute_message("WARNING: Same attribute name with differing values across machines", machine.name, attribute)
                puts "  #{congruency[attribute][:machine]}: #{congruency[attribute][:value]}"
                puts "  #{machine.name}: #{value}"
              end
            end
          end
        end

        0
      end

      def flat_hash(cur_val, cur_key=[], result={})
        return result.merge!({ cur_key => cur_val }) unless cur_val.is_a? Hash
        cur_val.each do |key, value| 
          flat_hash(value, cur_key + [key.to_sym], result) 
        end
        result
      end

      def print_attribute_message(message, machine_name, attribute)
        print "#{message} - #{machine_name}: "
        attribute.each {|subkey| print "[:#{subkey}]"}
        puts ""
      end
    end
  end
end
