require 'facets/module/cattr'
require 'fileutils'
require 'git'
require 'logging-helper'
require 'berkshelf/smart'
require 'etc'

require 'chef/handler/json_file'

def address_issues_where_ohai_is_slow()
  Ohai::Config[:disabled_plugins].push :Passwd
end

def disable_ohai_plugins_with_missing_dependencies
  Ohai::Config[:disabled_plugins].push(*[
    :Network,
    :NetworkRoutes,
    :NetworkListeners,
    :Elixir,
    :Erlang,
    :Go,
    :Groovy,
    :Lua,
    :LSB,
    :Nodejs,
    :Rust,
    :DMI,
    :GCE,
    :Virtualbox,
    :Virtualization,
    :Azure,
    :CPU,
    :Filesystem,
    :C,
    :Java,
    :Mono,
    :Perl,
    :PHP,
    :Powershell,
    :Python,
    :Ruby,
    :Scala,
    :EC2,
    :Rackspace,
    :Eucalyptus,
    :Linode,
    :Openstack,
    :DigitalOcean,
    :Softlayer,
    :BlockDevice,
    :Mdadm,
    :Sessions,
    :RootGroup,
    :Zpools,
    :VMware,
    :PS,
    :Filesystem2,
    :SystemProfile,
    :InitPackage
  ]).uniq!
end

node_name "#{$WORKSPACE_SETTINGS[:project][:name]}.local"

disable_ohai_plugins_with_missing_dependencies
address_issues_where_ohai_is_slow

log_level :debug
log_location STDOUT

cattr_reader :berk_workspace_path, :berk_workspace_project_path, :berks_cookbooks_path, :berks_flag_file_path, :report_dir_path, :berk_cache_path

@@report_dir_path = File.expand_path("reports/chef", $WORKSPACE_SETTINGS[:paths][:tmp][:dir])

def make_dir_with_correct_rights(dir)
	return if File.exist?(dir)
	FileUtils.mkdir_p dir
	FileUtils.chown_R(ENV['USER'], nil, dir)
end


make_dir_with_correct_rights report_dir_path
report_handlers << Chef::Handler::JsonFile.new(:path => report_dir_path)
exception_handlers << Chef::Handler::JsonFile.new(:path => report_dir_path)


@@berk_workspace_path = File.expand_path("workspace", $WORKSPACE_SETTINGS[:paths][:organization][:berkshelf][:home])
@@berk_workspace_project_path = File.expand_path($WORKSPACE_SETTINGS[:project][:name], berk_workspace_path)
@@berks_cookbooks_path = File.expand_path(Git.branch_name, berk_workspace_project_path)
@@berks_flag_file_path = File.expand_path(".berkshelf-flag", berks_cookbooks_path)
@@berk_cache_path = File.expand_path('.cache', $WORKSPACE_SETTINGS[:paths][:organization][:berkshelf][:home])

make_dir_with_correct_rights $WORKSPACE_SETTINGS[:paths][:organization][:berkshelf][:home]
make_dir_with_correct_rights berk_workspace_path
make_dir_with_correct_rights berk_workspace_project_path
make_dir_with_correct_rights berks_cookbooks_path
make_dir_with_correct_rights berk_cache_path

begin
  berkshelf = Berkshelf::Berksfile.from_file($WORKSPACE_SETTINGS[:paths][:project][:workspace][:settings][:chef][:cookbook][:workspace][:berksfile])

  smart_berks = Berkshelf::Smart.new(
    berkshelf,
    berks_flag_file_path,
    berks_cookbooks_path
  )

  took_action = smart_berks.ensure_cookbooks_are_uptodate

  if took_action
    FileUtils.chown(ENV['USER'], nil, berks_flag_file_path)
    FileUtils.chown(ENV['USER'], nil, berkshelf.lockfile.filepath) if Etc.getpwuid(File.stat(berkshelf.lockfile.filepath).uid).name == 'root' rescue false
    FileUtils.chown_R(ENV['USER'], nil, File.expand_path("cookbooks", $WORKSPACE_SETTINGS[:paths][:organization][:berkshelf][:home]))
    FileUtils.chown_R(ENV['USER'], nil, berks_cookbooks_path)
    FileUtils.chown_R(ENV['USER'], nil, berk_cache_path)
  end
rescue Exception => e
  LoggingHelper::LogToTerminal::Logger.error %|
#{e.message}
  #{e.backtrace.join("\n  ")}
|
  exit 1
end

cookbook_path [
  $WORKSPACE_SETTINGS[:paths][:project][:workspace][:settings][:chef][:cookbook][:home],
  berks_cookbooks_path
]

file_cache_path "/var/chef/cache"
file_backup_path "/var/chef/backup"
role_path "/var/chef/roles"

FileUtils.mkdir_p file_cache_path unless File.exist? file_cache_path
FileUtils.mkdir_p file_backup_path unless File.exist? file_backup_path
FileUtils.mkdir_p role_path unless File.exist? role_path

client_fork false
