require 'json'
require 'cfndsl'

module CfnDsl::Functions

  def protocol_number(name)
    protocols = {
      ah:   51,
  		esp:  50,
  		udp:  17,
  		tcp:  6,
  		icmp: 1,
  		all:  -1,
  		vrrp: 112
    }

    protocols[name.to_sym]
  end
end
