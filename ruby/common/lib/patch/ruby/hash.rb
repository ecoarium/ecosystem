
require 'patch/ruby/mixin/deep_join'

class Hash
  include DeepJoin

  def join(keyvaldelim=$,, entrydelim=$,)
    map {|e| e.join(keyvaldelim) }.join(entrydelim)
  end
end