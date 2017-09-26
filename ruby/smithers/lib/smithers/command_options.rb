require 'mixlib/cli'

module Smithers
  class CommandOptions
    include Mixlib::CLI

    option :smithers_file_path,
      :short => "-f FILE_PATH",
      :long  => "--file FILE_PATH",
      :description => "This is the path to the Smithersfile.",
      :default => 'Smithersfile'

    option :jenkins_url,
      :short => "-u URL",
      :long  => "--url URL",
      :description => "This is the url to the jenkins master.",
      :default => 'http://localhost:8080'

    option :jenkins_username,
      :short => "-n USERNAME",
      :long  => "--username USERNAME",
      :description => "This is the username to the jenkins master."

    option :jenkins_password,
      :short => "-p PASSWORD",
      :long  => "--password PASSWORD",
      :description => "This is the password to the jenkins master."

    option :jenkins_ssl,
      :short => "-s SSL",
      :long  => "--ssl SSL",
      :description => "This flag indicates if the jenkins master is accessible over ssl.",
      :default => false

    option :to_stdout,
      :short => "-o STDOUT",
      :long  => "--stdout STDOUT",
      :description => "This flag directs that job configuration to stdout instead of to a server.",
      :default => false

    option :help,
      :short => "-h",
      :long => "--help",
      :description => "Smithers options",
      :on => :tail,
      :show_options => true,
      :exit => 0
  end
end