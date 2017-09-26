
require 'logging-helper'

module VagrantPlugins
  module Reports
    module Reporter
      class Provider
        class VSphere
          extend LoggingHelper::LogToTerminal
          
          class << self
            
            def generate_report(machine, project_machine)
              hash = project_machine.configuration.provider.deep_to_hash
              hash.delete("vagrant_machine")
              hash
            end

          end
        end
      end
    end
  end
end