
class Iconv
  class << self
  	def conv(to, from, string)
  		string.encode(to, from)
  	end
  end
end