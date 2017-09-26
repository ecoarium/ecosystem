require 'git'

module Ecosystem
  class Version
    class << self

      MAJOR_VERSION = 1
      MINOR_VERSION = 0

      def current_version
        this_dir = File.expand_path(File.dirname(__FILE__))
        return Git.tag_name(this_dir) if !Git.tag_name(this_dir).nil?

        "#{MAJOR_VERSION}.#{MINOR_VERSION}.#{Git.version(this_dir)}.#{Git.branch_name(this_dir)}"
      end
    end
  end
end
