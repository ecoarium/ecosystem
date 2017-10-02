require 'fileutils'

module Berkshelf
  module FileSyncer
    def sync(source, destination, options = {})
      unless File.directory?(source)
        raise ArgumentError, "`source' must be a directory, but was a " \
          "`#{File.ftype(source)}'! If you just want to sync a file, use " \
          "the `copy' method instead."
      end

      # Reject any files that match the excludes pattern
      excludes = Array(options[:exclude]).map do |exclude|
        [exclude, "#{exclude}/*"]
      end.flatten

      excludes_directories = %w{ .git }

      source_files = glob(File.join(source, '**/*'))
      source_files = source_files.reject do |source_file|
        basename = relative_path_for(source_file, source)
        exclude_by_file_name = excludes.any? { |exclude| File.fnmatch?(exclude, basename, File::FNM_DOTMATCH) }

        exclude_by_directory_name = excludes_directories.any?{|exclude|
          source_file.include?("/#{exclude}/")
        }

        exclude_by_file_name or exclude_by_directory_name
      end

      # Ensure the destination directory exists
      FileUtils.mkdir_p(destination) unless File.directory?(destination)

      # Copy over the filtered source files
      source_files.each do |source_file|
        relative_path = relative_path_for(source_file, source)

        # Create the parent directory
        parent = File.join(destination, File.dirname(relative_path))
        FileUtils.mkdir_p(parent) unless File.directory?(parent)

        case File.ftype(source_file).to_sym
        when :directory
          FileUtils.mkdir_p("#{destination}/#{relative_path}")
        when :link
          target = File.readlink(source_file)

          destination = File.expand_path(destination)
          Dir.chdir(destination) do
            FileUtils.ln_sf(target, "#{destination}/#{relative_path}")
          end
        when :file
          FileUtils.cp(source_file, "#{destination}/#{relative_path}")
        else
          type = File.ftype(source_file)
          raise RuntimeError, "Unknown file type: `#{type}' at " \
            "`#{source_file}'. Failed to sync `#{source_file}' to " \
            "`#{destination}/#{relative_path}'!"
        end
      end

      # Remove any files in the destination that are not in the source files
      destination_files = glob("#{destination}/**/*")

      # Calculate the relative paths of files so we can compare to the
      # source.
      relative_source_files = source_files.map do |file|
        relative_path_for(file, source)
      end
      relative_destination_files = destination_files.map do |file|
        relative_path_for(file, destination)
      end

      # Remove any extra files that are present in the destination, but are
      # not in the source list
      extra_files = relative_destination_files - relative_source_files
      extra_files.each do |file|
        FileUtils.rm_rf(File.join(destination, file))
      end

      true
    end

    def relative_path_for(path, parent)
      Pathname.new(path).relative_path_from(Pathname.new(parent)).to_s
    end
  end
end
