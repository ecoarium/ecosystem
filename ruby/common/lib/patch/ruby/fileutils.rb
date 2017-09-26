require 'fileutils'

module FileUtils
  class << self
    def cp_f(source, target, opts={})
      FileUtils.mkdir_p(File.dirname(target)) unless Dir.exist?(File.dirname(target))
      FileUtils.rm_f(target) if File.exist? target
      FileUtils.cp(source, target)
    end
    def cp_rf(source, target, opts={})
      FileUtils.mkdir_p(File.dirname(target)) unless Dir.exist?(File.dirname(target))
      FileUtils.rm_rf(target) if File.exist? target
      FileUtils.cp_r(source, target)
    end
  end
end