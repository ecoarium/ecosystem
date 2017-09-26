require 'common/version'

module Jenkins
  class Version
    class << self
      def version_properties
        $WORKSPACE_SETTINGS[:application_version] = ENV['APPLICATION_VERSION'] || Common::Version.application_version
        $WORKSPACE_SETTINGS[:application_commit_hash] = ENV['APPLICATION_COMMIT_HASH'] || Common::Version.application_commit_hash

      	%/
APPLICATION_VERSION=#{$WORKSPACE_SETTINGS[:application_version]}
APPLICATION_COMMIT_HASH=#{$WORKSPACE_SETTINGS[:application_commit_hash]}
/
      end
    end
  end
end