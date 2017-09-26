require 'thread'

module Safe
  class IO
    
    @@io_lock_table = {}

    def self.action(path)
      raise "a closure is required, the safe action would be within the closure" unless block_given?
      @@io_lock_table[path] = Mutex.new unless @@io_lock_table.has_key?(path)
      lock = @@io_lock_table[path]

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
