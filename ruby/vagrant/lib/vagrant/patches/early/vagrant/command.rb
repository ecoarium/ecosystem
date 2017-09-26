
require "vagrant/plugin/v2/command"

module Vagrant
  module Plugin
    module V2
      class Command

        def with_target_vms(names=nil, options=nil)
          @logger.debug("Getting target VMs for command. Arguments:")
          @logger.debug(" -- names: #{names.inspect}")
          @logger.debug(" -- options: #{options.inspect}")

          # Setup the options hash
          options ||= {}

          # Require that names be an array
          names ||= []
          names = [names] if !names.is_a?(Array)

          # Determine if we require a local Vagrant environment. There are
          # two cases that we require a local environment:
          #
          #   * We're asking for ANY/EVERY VM (no names given).
          #
          #   * We're asking for specific VMs, at least once of which
          #     is NOT in the local machine index.
          #
          requires_local_env = false
          requires_local_env = true if names.empty?
          requires_local_env ||= names.any? { |n|
            !@env.machine_index.include?(n)
          }
          raise Errors::NoEnvironmentError if requires_local_env && !@env.root_path

          # Cache the active machines outside the loop
          active_machines = @env.active_machines

          # This is a helper that gets a single machine with the proper
          # provider. The "proper provider" in this case depends on what was
          # given:
          #
          #   * If a provider was explicitly specified, then use that provider.
          #     But if an active machine exists with a DIFFERENT provider,
          #     then throw an error (for now), since we don't yet support
          #     bringing up machines with different providers.
          #
          #   * If no provider was specified, then use the active machine's
          #     provider if it exists, otherwise use the default provider.
          #
          get_machine = lambda do |name|
            # Check for an active machine with the same name
            provider_to_use = options[:provider]
            provider_to_use = provider_to_use.to_sym if provider_to_use

            # If we have this machine in our index, load that.
            entry = @env.machine_index.get(name.to_s)
            if entry
              @env.machine_index.release(entry)

              # Create an environment for this location and yield the
              # machine in that environment. We silence warnings here because
              # Vagrantfiles often have constants, so people would otherwise
              # constantly (heh) get "already initialized constant" warnings.
              begin
                env = entry.vagrant_env(
                  @env.home_path, ui_class: @env.ui_class)
              rescue Vagrant::Errors::EnvironmentNonExistentCWD
                # This means that this environment working directory
                # no longer exists, so delete this entry.
                entry = @env.machine_index.get(name.to_s)
                @env.machine_index.delete(entry) if entry
                raise
              end

              next env.machine(entry.name.to_sym, entry.provider.to_sym)
            end

            active_machines.each do |active_name, active_provider|
              if name == active_name
                # We found an active machine with the same name

                if provider_to_use && provider_to_use != active_provider
                  # We found an active machine with a provider that doesn't
                  # match the requested provider. Show an error.
                  raise Errors::ActiveMachineWithDifferentProvider,
                    name: active_name.to_s,
                    active_provider: active_provider.to_s,
                    requested_provider: provider_to_use.to_s
                else
                  # Use this provider and exit out of the loop. One of the
                  # invariants [for now] is that there shouldn't be machines
                  # with multiple providers.
                  @logger.info("Active machine found with name #{active_name}. " +
                               "Using provider: #{active_provider}")
                  provider_to_use = active_provider
                  break
                end
              end
            end

            # Use the default provider if nothing else
            provider_to_use ||= @env.default_provider(machine: name)

            # Get the right machine with the right provider
            @env.machine(name, provider_to_use)
          end

          potential_machines = {}
          @env.machine_names.map do |machine_name|
            potential_machines[machine_name] = get_machine.call(machine_name)
          end

          # First determine the proper array of VMs.
          machines = []
          if names.length > 0
            names.each do |name|
              if pattern = name[/^\/(.+?)\/$/, 1]
                @logger.debug("Finding machines that match regex: #{pattern}")

                # This is a regular expression name, so we convert to a regular
                # expression and allow that sort of matching.
                regex = Regexp.new(pattern)

                @env.machine_names.each do |machine_name|
                  if machine_name =~ regex
                    machines << potential_machines[machine_name]
                  end
                end

                raise Errors::VMNoMatchError if machines.empty?
              else
                # String name, just look for a specific VM
                @logger.debug("Finding machine that match name: #{name}")
                machines << potential_machines[name.to_sym]
                raise Errors::VMNotFoundError, name: name if !machines[0]
              end
            end
          else
            # No name was given, so we return every VM in the order
            # configured.
            @logger.debug("Loading all machines...")
            machines = potential_machines.values
          end

          # Make sure we're only working with one VM if single target
          if options[:single_target] && machines.length != 1
            @logger.debug("Using primary machine since single target")
            primary_name = @env.primary_machine_name
            raise Errors::MultiVMTargetRequired if !primary_name
            machines = [potential_machines[primary_name]]
          end

          # If we asked for reversed ordering, then reverse it
          machines.reverse! if options[:reverse]

          # Go through each VM and yield it!
          color_order = [:default]
          color_index = 0

          machines.each do |machine|
            # Set the machine color
            machine.ui.opts[:color] = color_order[color_index % color_order.length]
            color_index += 1

            @logger.info("With machine: #{machine.name} (#{machine.provider.inspect})")
            yield machine

            # Call the state method so that we update our index state. Don't
            # worry about exceptions here, since we just care about updating
            # the cache.
            begin
              # Called for side effects
              machine.state
            rescue Errors::VagrantError
            end
          end
        end
      end
    end
  end
end