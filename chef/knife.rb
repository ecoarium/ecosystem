log_level                :debug
log_location             STDOUT
ssl_verify_mode          :verify_none
node_name                'build'
client_key               ENV['Chef_Client_Key'] || File.dirname(__FILE__) + '/build.pem'
validation_client_name   'chef-validator'
validation_key           ENV['Chef_Validation_Key'] || File.dirname(__FILE__) + '/validation.pem'
chef_server_url          "https://chef.#{$WORKSPACE_SETTINGS[:domain_name]}"
cache_type               'BasicFile'
cache_options( :path => '/var/chef/cache/checksums' )
cookbook_path [
  $WORKSPACE_SETTINGS[:paths][:project][:deploy][:chef][:cookbook][:home]
]

data_bag_path ENV['CHEF_DATA_BAGS_HOME'] || $WORKSPACE_SETTINGS[:paths][:project][:deploy][:chef][:data][:bags][:home]

json_attribs File.expand_path('node.json', File.dirname(__FILE__))

file_backup_path "/var/chef/backup"
role_path "/var/chef/roles"
