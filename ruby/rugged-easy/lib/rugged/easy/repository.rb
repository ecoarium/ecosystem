require 'rugged'
require 'pathname'

module Rugged
  module Easy
    class Repository
      attr_reader :path

      def initialize(dir, **opts, &block)
        @opts = opts
        @path = Pathname(dir)
        raise 'Supplied path is a file; expected a directory or nonexistent path.' if path.file?
        if block_given?
          case block.arity
            when 0
              instance_eval &block
            when 1
              block.call self
            when 2
              block.call self, repo
            else
              raise ArgumentError, 'Expected a block that takes 0-2 arguments'
          end
        end
      end

      def clone(url, opts={})
        Rugged::Repository.clone_at(url, path.to_s, opts)
        self
      end

      def init(*args)
        Rugged::Repository.init_at path, args.include?(:bare)
        self
      end

      def add(*globs)
        root = path.realpath
        index = repo.index
        globs.each do |glob|
          Dir[root + glob].each do |abs_path|
            abs_path = Pathname(abs_path)
            next if abs_path.directory?
            rel_path = abs_path.relative_path_from(root)
            index.add path: rel_path.to_s,
                      mode: abs_path.stat.mode,
                      oid:  Rugged::Blob.from_workdir(repo, rel_path.to_s)
          end
        end
        index.write
        self
      end

      def commit(*args)
        symbols, strings = split_args(*args)
        amend            = symbols.include? :amend
        index            = repo.index
        data             = {
            author:     author,
            committer:  author,
            message:    strings.first || '',
            update_ref: 'HEAD'
        }
        index.reload
        if amend
          data[:tree] = index.write_tree
          repo.head.target.amend data
        else
          data[:parents] = []
          unless repo.head_unborn?
            data[:parents] << repo.head.target.oid
          end

          data[:tree] = index.write_tree

          Rugged::Commit.create(repo, data)
        end
        self
      end

      def reset(reset_type, target)
        if target.to_s.upcase == 'HEAD'
          branch = repo.branches.each.find{|branch| branch.head?}
          target = "#{branch.remote_name}/#{branch.name}"
        elsif target.is_a? Rugged::Commit
          target = target.oid
        end

        repo.reset(target, reset_type)
      end

      def author
        {
            name:  get_option(:user_name),
            email: get_option(:user_email),
            time:  Time.now
        }
      end

      def get_option(key)
        @opts[key] || Easy.get_option(key)
      end

      def split_args(*args, **opts)
        symbols, strings = args.partition { |arg| arg.is_a? Symbol }
        symbols.concat opts.keys
        strings.concat opts.values
        [symbols, strings]
      end

      def repo
        Rugged::Repository.new(path.to_s)
      end

      def exist?
        !repo.bare?.nil? or !repo.empty?.nil? rescue false
      end

      def method_missing(method_symbol, *args, &block)
        unless repo.respond_to?(method_symbol)
          raise "method not found: #{method_symbol}. It's not on this class: #{self.inspect}, and Ruged::Repository does not respond_to the method either."
        end

        repo.method(method_symbol).call(*args, &block)
      end

    end
  end
end
