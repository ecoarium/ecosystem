module Berkshelf
  class CachedCookbook < Ridley::Chef::Cookbook
    class << self
      def from_store_path(path)
        path        = Pathname.new(path)
        cached_name = File.basename(path.to_s).slice(DIRNAME_REGEXP, 1)
        return nil if cached_name.nil?

        unless loaded_cookbooks.has_key?(path.to_s)
        	loaded_cookbooks[path.to_s] = from_path(path)	
        end

        loaded_cookbooks[path.to_s]
      end

      private

      def loaded_cookbooks
        @loaded_cookbooks ||= {}
      end
    end
  end
end