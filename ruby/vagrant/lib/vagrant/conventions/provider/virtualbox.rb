
module Vagrant
  module Conventions
    module Provider
      class VirtualBox
        class << self
          def format_machine_name(short_machine_name)
            [
              $WORKSPACE_SETTINGS[:project][:name],
              short_machine_name,
              $WORKSPACE_SETTINGS[:vagrant][:context].gsub('/', '-')
            ].join($WORKSPACE_SETTINGS[:delimiter])
          end
        end
      end
    end
  end
end