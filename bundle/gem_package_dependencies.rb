

def gem_package_dependencies(brew: [], yum: [], pacman: [])
  return unless $0.end_with?('bundle')
  GemPackageDependencies::Manager.process_dependencies(GemPackageDependencies::Brew, brew)
  GemPackageDependencies::Manager.process_dependencies(GemPackageDependencies::Yum, yum)
  GemPackageDependencies::Manager.process_dependencies(GemPackageDependencies::PacMan, pacman)
end

module GemPackageDependencies
  class Manager
    class << self
      def process_dependencies(klass, packages)
        return unless klass.on_platform?

        packages.each{|package|
          if package.is_a? String
            package = {name: package}
          end
          klass.new(package).ensure_installed
        }
      end
    end
  end
  class Yum
    attr_reader :package, :current_version

    def self.on_platform?
      `which yum 2>/dev/null 1>/dev/null`
      $?.exitstatus == 0
    end

    def initialize(package)
      @package = package

      output = `rpm -q --queryformat '%{NAME} %{VERSION}-%{RELEASE}\n' #{package[:name]} 2>&1`
      if $?.exitstatus == 0
        matches = output.strip.match(/([\w\d_.-]+)\s([\w\d_.-]+)/)
        @current_version = matches[2]
        @installed = true
      end
    end

    def ensure_installed
      if !installed?
        install
      elsif !package[:version].nil? and package[:version] != current_version
        raise "the current version of #{package[:name]} is #{info[:versions][:stable]}, you requested version #{package[:version]}" if package[:version] != info[:versions][:stable]
        install
      end
    end

    def install
      command = "sudo yum -d0 -e0 -y install #{package[:name]}"
      command = "#{command}-#{package[:version]}" unless package[:version].nil?
      output = `#{command} 2>&1`
      raise "failed to install #{package[:name]}:\n#{command}\n#{output}" unless $?.exitstatus == 0
    end

    def installed?
      @installed
    end
  end
  class PacMan
    attr_reader :package

    def self.on_platform?
      `which pacman 2>/dev/null 1>/dev/null`
      $?.exitstatus == 0
    end

    def initialize(package)
      @package = package
    end

    def ensure_installed
      if !installed?
        install
      elsif !package[:version].nil? and package[:version] != current_version
        raise "the current version of #{package[:name]} is #{installed_version}, you requested version #{package[:version]}" if package[:version] != current_version
        install
      end
    end

    def install
      output = `pacman -S --noconfirm #{package[:name]} 2>&1`
      raise "failed to install #{package[:name]}:\n#{output}" unless $?.exitstatus == 0
    end

    def installed?
      !current_version.nil?
    end

    def current_version
      return @current_version unless @current_version.nil?

      dump = `pacman -Q #{package[:name]} 2>&1`
      raise "failed to find info on #{package[:name]}:\n#{dump}" unless $?.exitstatus == 0
      @current_version = dump.chomp!.split(/\s+/)[1]
    end
  end
  class Brew
    attr_reader :package

    def self.on_platform?
      `which brew 2>/dev/null 1>/dev/null`
      $?.exitstatus == 0
    end

    def initialize(package)
      @package = package
    end

    def ensure_installed
      if !installed?
        install
      elsif !package[:version].nil? and package[:version] != current_version
        raise "the current version of #{package[:name]} is #{info[:versions][:stable]}, you requested version #{package[:version]}" if package[:version] != info[:versions][:stable]
        install
      end
    end

    def install
      output = `RUBYOPT='' BUNDLE_BIN_PATH='' brew install #{package[:name]} 2>&1`
      raise "failed to install #{package[:name]}:\n#{output}" unless $?.exitstatus == 0
    end

    def installed?
      !info["installed"].empty?
    end

    def current_version
      info["installed"].last["version"]
    end

    def info
      return @info unless @info.nil?
      require 'json'
      dump = `RUBYOPT='' brew info --json=v1 #{package[:name]} 2>&1`
      raise "failed to find info on #{package[:name]}:\n#{dump}" unless $?.exitstatus == 0
      @info = JSON.parse(dump).first
    end
  end
end
