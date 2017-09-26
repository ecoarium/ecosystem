
require 'logging-helper'

module VagrantPlugins
  module Reports
    module Reporter
      class Provider
        class Managed
          extend LoggingHelper::LogToTerminal
          
          class << self
            
            def generate_report(machine, project_machine)
              project_machine.configuration.provider.deep_to_hash
            end

          end
        end
      end
    end
  end
end