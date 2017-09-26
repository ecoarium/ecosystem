require 'shell-helper'
require 'berkshelf'
require 'logging-helper'
require 'fileutils'

module Berkshelf
	class Smart
    include LoggingHelper::LogToTerminal
    include ShellHelper::Shell

    ACTIONS = [
      :cache,
      :install,
      :update
    ]

    DEFAULT_ACTION = :none

    attr_reader :berkshelf, :berks_lock_file_path, :berks_flag_file_path, :berks_cookbooks_path, :action_override

    def initialize(berkshelf, berks_flag_file_path, berks_cookbooks_path, opts={})
      @berkshelf = berkshelf
      @berks_lock_file_path = berkshelf.lockfile.filepath
      @berks_flag_file_path = berks_flag_file_path
      @berks_cookbooks_path = berks_cookbooks_path

      unless opts[:action_override].nil?
        validate_action(opts[:action_override])
        @action_override = opts[:action_override]
      end
      
      if @action_override.nil? and !ENV['BERKSHELF_ACTION'].nil?
        validate_action(ENV['BERKSHELF_ACTION'].downcase.to_sym)
        @action_override = ENV['BERKSHELF_ACTION'].downcase.to_sym
      end

      debug {
"
Berkshelf::Smart:
  :berks_lock_file_path -> #{berks_lock_file_path}
  :berks_flag_file_path -> #{berks_flag_file_path}
  :berks_cookbooks_path -> #{berks_cookbooks_path}
  :action_override -> #{action_override}
"
      }
    end

    def ensure_cookbooks_are_uptodate()
      took_action = false
      if use_berkshelf_cache?
        info "using cache of existing berkshelf vendored cookbooks: #{berks_cookbooks_path}"
      else
        took_action = true

        if should_update_berkshelf?
          info "updating berkshelf cookbook cache"
          berkshelf.update
        else
          info "installing berkshelf cookbook cache"
          berkshelf.install
        end

        info "vendoring berkshelf cookbooks to: #{berks_cookbooks_path}"
        berkshelf.vendor(berks_cookbooks_path)

        touch_berks_flag_file
      end
      return took_action
    end

    private

    def validate_action(action_as_symbol)
      raise "action cannot be nil" if action_as_symbol.nil?
      if action_as_symbol.is_a?(Symbol)
        bad_action(action_as_symbol) if !ACTIONS.include?(action_as_symbol)
      else
        bad_action(action_as_symbol)
      end
    end

    def bad_action(value)
      error %/
#{value.inspect} is not a valid action, please choose one of the following:
  * #{ACTIONS.join("\n  * ")}
/
      raise "#{value.inspect} is not a valid action"
    end

    def override?()
      !action_override.nil?
    end

    def override(action)
      action == action_override
    end

    def touch_berks_flag_file
      FileUtils.touch(berks_flag_file_path) unless File.exist?(berks_flag_file_path)
      touch_time = Time.now + 1
      File.utime(touch_time, touch_time, berks_flag_file_path)
    end

    def use_berkshelf_cache?
      return override(:cache) if override?
      File.exist? berks_lock_file_path and 
        FileUtils.uptodate?(berks_flag_file_path, [berks_lock_file_path].concat(berkshelf.included_berks_files)) and
        !shell_true?("grep '    path:' #{berks_lock_file_path}")
    end

    def should_update_berkshelf?
      return override(:update) if override?
      File.exist? berks_lock_file_path and !FileUtils.uptodate?(berks_lock_file_path, berkshelf.included_berks_files)
    end

  end
end