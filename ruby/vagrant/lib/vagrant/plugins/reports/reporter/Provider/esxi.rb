
require 'logging-helper'

module VagrantPlugins
  module Reports
    module Reporter
      class Provider
        class ESXI
          extend LoggingHelper::LogToTerminal
          
          class << self
            
            def generate_report(machine, project_machine)
              project_machine.configuration.provider.network.ip_address
              hash = project_machine.configuration.provider.deep_to_hash
              hash.delete('vagrant_machine')
              hash['network'].delete('vagrant_machine')
              hash['network'].delete('formatter')
              hash
            end

          end
        end
      end
    end
  end
end