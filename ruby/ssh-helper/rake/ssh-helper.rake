require 'ssh-executor'
require 'ssh-keys'

task :switch_to_new_user, :server do |t, args|
	ssh_dir = File.expand_path(".ssh", directory)
  public_key_path = File.expand_path("id_rsa.pub", ssh_dir)
  create_ssh_key_pair(args.directory, passphrase: args.passphrase) unless File.exist?(public_key_path)

  switch_to_new_user(
  	args.server,
  	new_key_pair: {
  		ssh_public_key: public_key_path
  	}
	)
end

task :create_ssh_key_pair, :directory, :passphrase do |t, args|
  create_ssh_key_pair(args.directory, passphrase: args.passphrase)
end


def create_ssh_key_pair(directory, opts=nil)
  ssh_dir = File.expand_path(".ssh", directory)
  private_key_path = File.expand_path("id_rsa", ssh_dir)
  public_key_path = File.expand_path("id_rsa.pub", ssh_dir)

  unless File.exist? private_key_path
    opts = {
      :passphrase => SecureRandom.hex
    }.merge(opts || {})

    key_pair = SSHKey.generate(:type => "RSA", :bits => 1024, :passphrase => opts[:passphrase])

    FileUtils.mkdir_p(ssh_dir)
    sh "chmod 0700 #{ssh_dir}"

    File.open(private_key_path, 'w') do |file|
      file.write(key_pair.private_key)
    end
    sh "chmod 0600 #{private_key_path}"

    File.open(public_key_path, 'w') do |file|
      file.write(key_pair.ssh_public_key)
    end
    sh "chmod 0644 #{public_key_path}"

    ssh_public_key = key_pair.ssh_public_key
  else
    ssh_public_key = File.read(public_key_path)
  end

  {private_key_path: private_key_path, public_key_path: public_key_path, ssh_public_key: ssh_public_key}
end

def add_new_user(server, opts=nil)
  opts = {
    existing_user: 'vagrant',
    existing_users_private_key_path: $WORKSPACE_SETTINGS[:paths][:vagrant_home]
  }.merge(opts || {})

  new_key_pair = opts[:new_key_pair]
  new_key_pair = create_ssh_key_pair(server) if new_key_pair.nil? 
  new_user = SecureRandom.urlsafe_base64(5)
  new_password = SecureRandom.urlsafe_base64(5)

  puts %/
  creating new account:
  	server:						#{server}
  	new user:					#{new_user}
  	public_key_path:	#{public_key_path}
  /
  
  ssh_opts = {
    :port                  => 22,
    :keys                  => [opts[:existing_users_private_key_path]],
    :keys_only             => true,
    :user_known_hosts_file => [],
    :paranoid              => false,
    :config                => false,
    :forward_agent         => false
  }

  connection = Net::SSH.start(server, opts[:existing_user], ssh_opts)
  
  script = <<-EOF
    #
    useradd --create-home -s /bin/bash #{new_user}
    echo -n '#{new_user}:#{new_password}' | chpasswd
    echo '#{new_user} ALL = NOPASSWD: ALL' >> /etc/sudoers
    mkdir -p /home/#{new_user}/.ssh
    chmod 700 /home/#{new_user}/.ssh
    echo #{new_key_pair[:ssh_public_key]} > /home/#{new_user}/.ssh/authorized_keys
    chmod 600 /home/#{new_user}/.ssh/authorized_keys
    chown -R #{new_user}:#{new_user} /home/#{new_user}/.ssh
    #
  EOF
  execute_script(connection, script)
end