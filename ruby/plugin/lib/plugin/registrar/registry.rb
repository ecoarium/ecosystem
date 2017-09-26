
require 'patch/ruby/hash'

module Plugin
	module Registrar
		class Registry
			class << self
				def registry(name)
		      return registries[name] unless registries[name].nil?
					registries[name] = self.new
				end

				def add_class_location(registry, path)
					registry(registry).add_class_location(path)
				end

				def lookup(registry, friendly_name)
					registry(registry).lookup(friendly_name, registry)
				end

				def register(registry, friendly_name, klass)
					registry(registry).register(friendly_name, klass, registry)
				end

				private

				@@registries = {}
				def registries
					@@registries
				end
			end

			def initialize
				@registry = {}
				@class_locations = []
			end

			def add_class_location(path)
				raise "the path [#{path}] does not exist" unless File.exist? path
				class_locations << path

				Dir.glob("#{path}/**/*.rb") {|registrant|
					next if registrant.end_with?('base.rb')
					require registrant
				}
			end

			def lookup(friendly_name, registry_name)
				result = registry[friendly_name]
				raise(
				%/

the friendly registrant name #{friendly_name.inspect} is not registered in the registry #{registry_name.inspect}, class_locations:
\t#{class_locations.join("\n\t")}

if your registrant class is one if the paths listed above did you set the friendly_name in your class?

example:
class ExampleClass
register :example_friendly_name, self.inspect #<- you class needs this line to register itself

...
end

registrants registered:
  * #{registry.join(' - ', "\n  * ")}

/
				) if result.nil?

				return result
			end

			def register(friendly_name, klass, registry_name)
				klass = Object.const_get(klass) if klass.is_a? String
				raise %/

the friendly registrant name #{friendly_name} is already registered in the registry #{registry_name.inspect}:
existing:	  #{registry[friendly_name]}
requested: 	#{klass.name}

/ if registry.has_key?(friendly_name)
				registry[friendly_name] = klass
			end

			private

			attr_reader :registry, :class_locations
		end
	end
end