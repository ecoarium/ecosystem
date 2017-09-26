require "pathname"

module VagrantPlugins
  module ESXi
    lib_path = Pathname.new(File.expand_path("esxi", File.dirname(__FILE__)))
    autoload :Action, lib_path.join("action")
    autoload :Errors, lib_path.join("errors")

    def self.source_root
      @source_root ||= Pathname.new(File.dirname(__FILE__))
    end
  end
end
