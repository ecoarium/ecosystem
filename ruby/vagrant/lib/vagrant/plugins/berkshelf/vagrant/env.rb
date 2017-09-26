module Berkshelf
  module Vagrant
    # @author Jamie Winsor <jamie@vialstudios.com>
    #
    # Environment data to build up and persist through the middleware chain
    class Env
      # @return [Vagrant::UI::Colored]
      attr_accessor :ui
      # @return [Berkshelf::Berksfile]
      attr_accessor :berksfile
      # @return [StateFileManager]
      attr_accessor :state_file_manager
      # @return [Berkshelf::Config]
      attr_accessor :config

      def initialize
        @ui     = ::Vagrant::UI::Colored.new
        @config = Berkshelf::Config.instance
      end
    end
  end
end
