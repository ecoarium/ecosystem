require 'vagrant/rake/provider/virtualbox'

def provider
  return @provider unless @provider.nil?
  @provider = Vagrant::Rake::Provider::VirtualBox.new
end
provider.generate_tasks
