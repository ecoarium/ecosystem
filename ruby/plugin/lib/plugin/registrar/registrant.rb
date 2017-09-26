
module Plugin
  module Registrar
    module Registrant

    	def register(registry_name, registrant_name, klass)
        Registry.register(registry_name, registrant_name, klass)
    	end

      def registry(registry_name)
        Registry.registry(registry_name)
      end

    end
  end
end