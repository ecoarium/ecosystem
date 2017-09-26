
require 'vagrant/ui'

module Vagrant
  module UI
    class Interface
      [:ask, :detail, :warn, :error, :info, :output, :success].each do |method|
        define_method(method) do |message, *opts|
          
        end
      end
    end
  end
end