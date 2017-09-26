require 'vagrant/rake/provider/virtualbox'

def provider
  return @provider unless @provider.nil?
  @provider = Vagrant::Rake::Provider::VirtualBox.new
end
provider.generate_tasks


task :"rt_deploy_#{$WORKSPACE_SETTINGS[:project][:name].gsub(/-/, '_')}" => [:move_artifact]
