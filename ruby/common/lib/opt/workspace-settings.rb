require "json"

create_machine_report = true

if ARGV.include?('--no_machine_report')
  switch_index = ARGV.index('--no_machine_report')
  ARGV.delete_at(switch_index)
  create_machine_report = false
elsif ARGV.include?('-nmr')
  switch_index = ARGV.index('-nmr')
  ARGV.delete_at(switch_index)
  create_machine_report = false
end

ENV['CREATE_MACHINE_REPORT'] = "#{create_machine_report.inspect}"

$WORKSPACE_SETTINGS = {} if $WORKSPACE_SETTINGS.nil?

$WORKSPACE_SETTINGS[:workspace_setting] = ENV['WORKSPACE_SETTING']

$WORKSPACE_SETTINGS[:hats] = []

unless ENV['HATS'].nil?
	$WORKSPACE_SETTINGS[:hats] = ENV['HATS'].split(':').collect{|type|
		type.to_sym unless type.empty?
	}
end

$WORKSPACE_SETTINGS[:hats].uniq!
$WORKSPACE_SETTINGS[:hats].compact!

$WORKSPACE_SETTINGS[:test_types] = []

unless ENV['TEST_TYPES'].nil?
	$WORKSPACE_SETTINGS[:test_types] = ENV['TEST_TYPES'].split(':').collect{|type|
		type.to_sym unless type.empty?
	}
end

$WORKSPACE_SETTINGS[:test_types].uniq!
$WORKSPACE_SETTINGS[:test_types].compact!

workspace_settings = Hash.new { |hash,key| hash[key] = Hash.new(&hash.default_proc) }
ENV.each{|name,value|
	if name.start_with?('PATHS_') or name.start_with?('PROJECT_') or name.start_with?('ECOSYSTEM_') or name.start_with?('VAGRANT_') or name.start_with?('PACKER_') or name.start_with?('ORGANIZATION_') or name.start_with?('COMPANY_') or name.start_with?('GIT_') or name.start_with?('AWS_')
		eval "workspace_settings[:#{name.downcase.gsub(/_/, '][:')}] = value"
		# puts "workspace_settings[:#{name.downcase.gsub(/_/, '][:')}] = '#{value}'"
	end
}

$WORKSPACE_SETTINGS.deep_merge!(JSON.parse(JSON.generate(workspace_settings),:symbolize_names => true))

$WORKSPACE_SETTINGS.deep_merge!({
	delimiter: ENV['DELIMITER'],
	start_time: Time.now,
	application_short_version_prefix: ENV['APPLICATION_SHORT_VERSION_PREFIX'],
	application_long_version_prefix: ENV['APPLICATION_LONG_VERSION_PREFIX'],
  domain_name: ENV['DOMAIN_NAME'],
	nexus: {
		base_coordinates: {
			artifact_id: ENV['ARTIFACT_ID_BASE'],
			group_id: ENV['GROUP_ID_BASE']
		},
		base_url: "https://nexus.#{ENV['DOMAIN_NAME']}",
		rest_end_point: "https://nexus.#{ENV['DOMAIN_NAME']}/service/local/artifact/maven/redirect",
		direct_base_path: "https://nexus.#{ENV['DOMAIN_NAME']}:8443/repositories",
		repos: {
			file: 'filerepo',
			release: 'releases'
		},
		credentials: {
			user_name: ENV['NEXUS_USER_NAME'],
			password: ENV['NEXUS_PASSWORD']
		}
	},
	build_artifact_directory_name: '.build',
	paths: {
		project: {
			deploy: {
				runtime_share: {
					context: {
						home: "#{$WORKSPACE_SETTINGS[:paths][:project][:deploy][:home]}/runtime-share/#{$WORKSPACE_SETTINGS[:vagrant][:context]}"
					}
				}
			}
		}
	},
  iserver_branch: ENV['ISERVER_BRANCH']
})
