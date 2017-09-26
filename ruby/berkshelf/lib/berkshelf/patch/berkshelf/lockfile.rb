
module Berkshelf
  class Lockfile
    class << self
      def from_berksfile(berksfile, options = {})
        if options[:lock_file_path].nil?
          parent = File.expand_path(File.dirname(berksfile.filepath))
          lockfile_name = "#{File.basename(berksfile.filepath)}.lock"
          filepath = File.join(parent, lockfile_name)
        else
          filepath = options[:lock_file_path]
        end
        
        new(berksfile: berksfile, filepath: filepath)
      end
    end
  end
end