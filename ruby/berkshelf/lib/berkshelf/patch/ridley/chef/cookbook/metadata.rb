
module Ridley::Chef
  class Cookbook
    class Metadata

    	attr_writer :from_file_path

    	def from_file_path
    		return @from_file_path unless @from_file_path.nil?
    		caller_line = caller.find{|candidate|
    			caller_file_path, line_number, method = candidate.split(':')
    			method == "in `from_file'" and caller_file_path.end_with?("/metadata.rb") and caller_file_path !~ /ridley\/chef\/cookbook/
    		}
    		@from_file_path = caller_line.split(':')[0]
    		@from_file_path
    	end

    	def from_file(filename)
	      filename = filename.to_s
	      from_file_path = filename

	      ensure_presence!(filename)

	      with_error_handling(filename) do
	        self.instance_eval(IO.read(filename), filename, 1)
	        self
	      end
	    end

      def name(arg = nil)
        value = set_or_return(
          :name,
          arg,
          :kind_of => [ String ]
        )
        
        if arg.nil? and value.empty? and !from_file_path.nil? and !from_file_path.empty?
        	cookbook_name = File.basename(File.dirname(from_file_path)).gsub(/-#{Regexp.escape(cookbook_version)}/, '')
        	@name = cookbook_name

          current_content = IO.read(from_file_path)
          File.open(from_file_path, "w"){|file|
            file.puts "name '#{@name}'"
            file.puts current_content
          }
        end
        
        @name
      end

      def cookbook_version
      	return @cookbook_version unless @cookbook_version.nil?
      	@cookbook_version = version
        if @cookbook_version == '0.0.0'
        	@cookbook_version = File.basename(File.dirname(from_file_path)).gsub(/#{Regexp.escape(@name)}-/, '')

          current_content = IO.read(from_file_path)
          File.open(from_file_path, "w"){|file|
            file.puts "version '#{@cookbook_version}'"
            file.puts current_content
          }
        end
        @cookbook_version
      end

    end
  end
end
