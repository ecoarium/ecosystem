require 'thread'

module Safe
  class Resource
    
    @@resource_lock_table = {}

    def self.action(resource_name)
      raise "a closure is required, the safe action would be within the closure" unless block_given?
      @@resource_lock_table[resource_name] = Mutex.new unless @@resource_lock_table.has_key?(resource_name)
      lock = @@resource_lock_table[resource_name]

      begin
        lock.synchronize {}
      rescue ThreadError
        # If we already hold the lock, just create a new lock so we
        # definitely don't block and don't get an error.
        lock = Mutex.new
      end

      lock.synchronize do
        yield
      end
    end

  end
end
