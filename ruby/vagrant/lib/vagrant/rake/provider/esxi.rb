require "vagrant/rake/provider/common"

module Vagrant
  module Rake
    module Provider
      class ESXI
        include Vagrant::Rake::Provider::Common

        def initialize
          super
          load_provider_tasks
        end

        def provider_name
          "esxi"
        end

        def load_provider_tasks

        end

        def current_compared_to_flag?(machine, source_exclutions=[])
          is_current = false

          if machine_state_exist?(machine) and flag_exist?(machine)
            debug {
              "comparing machine #{machine} flag file against source files

  machine flag file:
    #{flag_file(machine)}

  source files:
    #{default_sources.join("\n    ")}
"
            }
            is_current = current?(flag_file(machine), default_sources, source_exclutions)
          end

          return is_current
        end

      end
    end
  end
end
