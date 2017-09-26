
module Ridley::Chef
  class Cookbook
    class << self

      def from_path(path)
        path = Pathname.new(path)

        metadata = nil

        if (file = path.join(Metadata::COMPILED_FILE_NAME)).exist?
          metadata = Metadata.from_json(File.read(file))
          metadata.from_file_path = file.to_s
          metadata = nil if metadata.name =~ /\s+/
        end
        
        if (file = path.join(Metadata::RAW_FILE_NAME)).exist?
          metadata = Metadata.from_file(file)
          metadata.from_file_path = file.to_s
        end

        if metadata.nil?
          raise IOError, "no #{Metadata::COMPILED_FILE_NAME} or #{Metadata::RAW_FILE_NAME} found at #{path}"
        end

        unless metadata.name.presence
          raise Ridley::Errors::MissingNameAttribute.new(path)
        end

        new(metadata.name, path, metadata)
      end

    end
  end
end
