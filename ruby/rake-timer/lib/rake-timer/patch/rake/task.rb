require 'rake/task'

module Rake
  class Task
    class Status
      class << self
        def success
          :success
        end
        def failure
          :failure
        end
        def not_run
          :not_run
        end
      end
    end

    def duration
      self.duration= 0 if @duration.nil?
      @duration
    end

    def duration=(duration)
      @duration = duration
    end

    def start
      self.start= Time.now if @start.nil?
      @start
    end

    def start=(start)
      @start = start
    end

    def status
      self.status= Status.not_run if @status.nil?
      @status
    end

    def status=(status)
      @status = status
    end

    alias_method :old_execute, :execute

    def execute(*args)
      self.start= Time.now

      self.status= Status.failure
      begin
        old_execute(*args)
        successful = true
      ensure
        self.duration= Time.now - start
      end

      self.status= Status.success
    end

  end
end
