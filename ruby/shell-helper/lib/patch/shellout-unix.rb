module Mixlib
  class ShellOut
    module Unix
      def read_stdout_to_buffer
        while chunk = child_stdout.read_nonblock(READ_SIZE)
          unless log_tag.nil?
            chunk = "#{log_tag} #{chunk}"
          end
          @stdout << chunk
          @live_stdout << chunk if @live_stdout
          logger.log(chunk, log_level) if logger
        end
      rescue Errno::EAGAIN
      rescue EOFError
        open_pipes.delete(child_stdout)
      end

      def read_stderr_to_buffer
        while chunk = child_stderr.read_nonblock(READ_SIZE)
          unless log_tag.nil?
            chunk = "#{log_tag} #{chunk}"
          end
          @stderr << chunk
          @live_stderr << chunk if @live_stderr
          logger.error(chunk) if logger
        end
      rescue Errno::EAGAIN
      rescue EOFError
        open_pipes.delete(child_stderr)
      end

      def propagate_pre_exec_failure
        begin
          attempt_buffer_read until child_process_status.eof?
          return nil if @process_status.nil? or @process_status.empty?
          e = Marshal.load(@process_status)
          raise(Exception === e ? e : "unknown failure: #{e.inspect}")
        rescue ArgumentError # If we get an ArgumentError error, then the exec was successful
          true
        ensure
          child_process_status.close
          open_pipes.delete(child_process_status)
        end
      end
      
      def reap_errant_child
        return if attempt_reap
        @terminate_reason = "Command exceeded allowed execution time, process terminated"
        logger.error("Command exceeded allowed execution time, sending TERM") if logger
        Process.kill(:TERM, child_pgid) unless child_pgid.nil?
        sleep 3
        attempt_reap
        logger.error("Command exceeded allowed execution time, sending KILL") if logger
        Process.kill(:KILL, child_pgid) unless child_pgid.nil?
        reap

        # Should not hit this but it's possible if something is calling waitall
        # in a separate thread.
      rescue Errno::ESRCH
        nil
      end
    end
  end
end
