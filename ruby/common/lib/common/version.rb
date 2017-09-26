require 'git'

module Common
  class Version
    class << self

      def application_version
        "#{$WORKSPACE_SETTINGS[:application_long_version_prefix]}#{Git.version}"
      end

      def application_commit_hash
      	Git.commit_hash
      end

      def application_branch
      	Git.branch_name
      end
    end
  end
end