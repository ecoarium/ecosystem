loaded_vagrant_gem_path = Gem::Specification.find_by_name('vagrant').gem_dir
require "#{loaded_vagrant_gem_path}/plugins/communicators/winrm/shell"

module VagrantPlugins
  module CommunicatorWinRM
    class WinRMShell

      def upload(from, to)
        file_manager = WinRM::FS::FileManager.new(session)
        file_manager.delete(to) if file_manager.exists?(to)
        file_manager.upload(from, to)
      end

      def handle_output(execute_method, command, &block)
        output = execute_method.call(command) do |out, err|
          block.call(:stdout, out) if block_given? && out
          block.call(:stderr, err) if block_given? && err
        end
        @executor.close

        @logger.debug("Output: #{output.inspect}")

        # Verify that we didn't get a parser error, and if so we should
        # set the exit code to 1. Parse errors return exit code 0 so we
        # need to do this.
        if output[:exitcode] == 0
          (output[:data] || []).each do |data|
            next if !data[:stderr]
            if data[:stderr].include?("ParserError")
              @logger.warn("Detected ParserError, setting exit code to 1")
              output[:exitcode] = 1
              break
            end
          end
        end

        return output
      end

      def executor
        @executor = session.create_executor
      end

    end
  end
end