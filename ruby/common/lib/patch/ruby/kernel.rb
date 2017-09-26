
module Kernel

	alias_method :original_require_relative, :require_relative
	def require_relative(partial_file_path)
		if RbConfig::CONFIG['host_os'].include?('mingw32')
			caller_file_path = caller[0].split(':')[1]
		else
			caller_file_path = caller[0].split(':')[0]
		end

		gem_path = $:.find{|gem_path_candidate|
			caller_file_path.start_with?(gem_path_candidate)
		}

		full_path_without_extention = File.expand_path(partial_file_path, File.dirname(caller_file_path))

		unless gem_path.nil?
			as_require = full_path_without_extention.gsub(/#{Regexp.escape(gem_path)}\//, '')
			require as_require
		else
			require "#{full_path_without_extention}.rb"
		end
	end

	def pretty_inspect
		require 'awesome_print'

		AwesomePrint.defaults = {
		  indent: -2,
		  plain:  true,
		  index:  false
		}

    self.ai
  end

end