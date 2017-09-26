
module Smithers
  module ConfigurationItems
    module Jobs
      class FreeStyleJob
        include LoggingHelper::LogToTerminal
        include Attributes::Mixin::Method
        include Plugin::MethodMissingIntercept::Flexible
        extend Plugin::Registrar::Registrant

        register :job, :job, self.inspect
        register :job, :free_style_job, self.inspect

        attr_reader :job_short_name, :additional_args, :environment, :configuration_block
        attr_reader :configuration

        attr_method(
          :quiet_period,
          :assigned_node,
          :assigned_node_number,
          {
            actions: {}
          },
          {
            description: 'no description'
          },
          {
            keep_dependencies: false
          },
          {
            block_build_when_downstream_building: false
          },
          {
            block_build_when_upstream_building: false
          },
          {
            can_roam: false
          },
          {
            concurrent_build: false
          }
        )

        def initialize(job_short_name, &block)
          @job_short_name = job_short_name
          @additional_args = additional_args
          @environment = Smithers::Environment
          @configuration_block = block

          environment.jobs[job_short_name] = self

          additional_arguments.push self

          @configuration = {}
          set_defaults
        end

        def branch_name
          environment.branch_name
        end

        def project_name
          environment.project_name
        end

        def name
          return @name unless @name.nil?
          @name = [
            project_name,
            branch_name,
            job_short_name
          ].join(environment.delimiter)
        end

        def assigned_node
          return nil if assigned_node_number.nil?
          if assigned_node_number.is_a? Integer
            "#{project_name}-.-#{branch_name}-.-#{assigned_node_number}"
          elsif assigned_node_number.is_a? Array
            assigned_node_number.collect {|num| "#{project_name}-.-#{branch_name}-.-#{num}"}.join(" || ")
          else
            raise 'assigned_node_number need to be either Integer or Array'
          end
        end

        def configure
          instance_exec(&configuration_block)

          plus = {
            time: Time.now.strftime('%Y-%m-%d')
          }.to_json

          description_plus = [description, plus].join("\n#{$WORKSPACE_SETTINGS[:delimiter]}\n")

          configuration.deep_merge!({
            'actions'                          => actions,
            'description'                      => description_plus,
            'keepDependencies'                 => keep_dependencies,
            'canRoam'                          => can_roam,
            'disabled'                         => true,
            'blockBuildWhenDownstreamBuilding' => block_build_when_downstream_building,
            'blockBuildWhenUpstreamBuilding'   => block_build_when_upstream_building,
            'concurrentBuild'                  => concurrent_build
          })

          unless assigned_node.nil?
            configuration['assignedNode'] = assigned_node
            configuration['canRoam'] = false
          end

          configuration['quietPeriod'] = quiet_period unless quiet_period.nil?

          debug configuration.pretty_inspect
        end

        def xml
          XmlSimple.xml_out(configuration, 'AttrPrefix' => true, 'RootName' => 'project' )
        end

        def registry_name
          :job_top_level
        end

        def plugin_action_method_name
          :configure
        end

        def signature
          [Proc]
        end

      end
    end
  end
end
