require 'vagrant/rake/provider/virtualbox'

provider = Vagrant::Rake::Provider::VirtualBox.new

provider.generate_tasks

task :hack_for_nfs_sudo do
  `sudo echo thanks`
end

task :rt_up_osx_workspace => :hack_for_nfs_sudo