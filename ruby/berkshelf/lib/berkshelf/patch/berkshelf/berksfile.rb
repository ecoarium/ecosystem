require 'logging-helper'

module Berkshelf
  class Berksfile
    class << self
      def from_file(file, options = {})
        raise BerksfileNotFound.new(file) unless File.exist?(file)

        begin
          shim_file_path = File.expand_path('../../berks_shim.rb', File.dirname(__FILE__))
          berksfile = new(shim_file_path, options)
          berksfile.filepath = file
          berksfile.include_berks_file(shim_file_path)
          berksfile.lockfile = Lockfile.from_berksfile(berksfile, options)

          prepositioned_berksfiles.each{|prepositioned_berksfile|
            berksfile.load_berks_file(prepositioned_berksfile)
          }

          preposition_berks_blocks.each{|block|
            berksfile.instance_eval &block
          }

          berksfile.load_berks_file(file)

          berksfile
        rescue => ex
          raise BerksfileReadError.new(ex)
        end
      end

      def preposition_berks_block(&block)
        @@preposition_berks_blocks.push block
      end

      def preposition_berksfile(file)
        @@prepositioned_berksfiles.push file
      end

      private

      @@preposition_berks_blocks = []
      def preposition_berks_blocks
        @@preposition_berks_blocks
      end

      @@prepositioned_berksfiles = []
      def prepositioned_berksfiles
        @@prepositioned_berksfiles
      end
    end

    include LoggingHelper::LogToTerminal

    def filepath=(value)
      @filepath = value
    end

    def lockfile=(value)
      @lockfile = value
    end

    def load_berks_file(file)
      include_berks_file(file)
      try_loading_overrides(file)
    end

    def try_loading_overrides(file)
      return if !ENV['BERKSHELF_IGNORE_OVERRIDES'].nil? and ENV['BERKSHELF_IGNORE_OVERRIDES'] == 'true'
      overrides_berks_file_path = "#{File.dirname(file)}/overrides.#{File.basename(file)}"
      if File.exists?(overrides_berks_file_path)
        LoggingHelper::LogToTerminal::Logger.warn "loading berkshelf overrides from: #{overrides_berks_file_path}"
        include_berks_file(overrides_berks_file_path)
      end
    end

    attr_reader :included_berks_files

    def include_berks_file(file_path)
      @included_berks_files = [] if @included_berks_files.nil?
      return if included_berks_files.include?(file_path)

      debug { "including berks file: #{file_path}" }
      raise "berks file does not exist: #{file_path}" unless File.exist?(file_path)
      @included_berks_files << file_path
      self.instance_eval(File.read(file_path), file_path, 1)
    end

    def vendor(destination)
      Dir.mktmpdir('vendor') do |scratch|
        chefignore       = nil
        cached_cookbooks = install

        return nil if cached_cookbooks.empty?

        cached_cookbooks.each do |cookbook|
          Berkshelf.formatter.vendor(cookbook, destination)
          cookbook_destination = File.join(scratch, cookbook.cookbook_name)
          FileUtils.mkdir_p(cookbook_destination)

          src   = cookbook.path.to_s.gsub('\\', '/')
          files = FileSyncer.glob(File.join(src, '*'))

          chefignore = Ridley::Chef::Chefignore.new(cookbook.path.to_s) rescue nil
          chefignore.apply!(files) if chefignore

          unless cookbook.compiled_metadata?
            cookbook.compile_metadata(cookbook_destination)
          end

          FileUtils.cp_r(files, cookbook_destination)
        end

        FileSyncer.sync(scratch, destination, exclude: EXCLUDED_VCS_FILES_WHEN_VENDORING)
      end

      destination
    end

    def add_dependency(name, constraint = nil, options = {})
		  options[:constraint] = constraint

		  if options[:path]
		    metadata_file = File.join(options[:path], 'metadata.rb')
		  end

		  new_dependency = Dependency.new(self, name, options)
		  if @dependencies[name]

		    groups = (options[:group].nil? || options[:group].empty?) ? [:default] : options[:group]
		    if !(@dependencies[name].groups & groups).empty? and
            new_dependency.name == @dependencies[name].name and
            new_dependency.version_constraint != @dependencies[name].version_constraint and
            new_dependency.location != @dependencies[name].location
		    	warn %/
					Berksfiles contains multiple sources '#{name}'
		      Overriding:
		        #{@dependencies[name].inspect}
		      With:
		        #{new_dependency.inspect}
/
		    end
		  end

		  @dependencies[name] = new_dependency
		end

   end
end
