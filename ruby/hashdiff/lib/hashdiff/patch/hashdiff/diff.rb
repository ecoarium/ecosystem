require 'hashdiff'

module HashDiff
  class << self
    alias :original_diff :diff
    def diff(obj1, obj2, options = {}, &block)
      if obj1.is_a?(Array)
        obj1.sort!
        obj2.sort!
      end
      original_diff(obj1, obj2, options, &block)
    end
  end
end