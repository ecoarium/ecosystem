Encoding.default_external = "UTF-8"
source "https://supermarket.chef.io"

def override_ecoarium_cookbook(name)
  cookbook name, path:  File.expand_path("github/ecoarium-cookbooks/#{name}", $WORKSPACE_SETTINGS[:paths][:projects][:root])
end

def ecoarium_cookbook(name, version)
  cookbook name, git: "https://github.com/ecoarium-cookbooks/#{name}.git", tag: version
end

def cookbook_from_github(oranization, name, version)
  cookbook name, git: "https://github.com/#{oranization}/#{name}.git", tag: version
end

def cookbook_from_git(oranization, name, version)
  cookbook name, git: "#{$WORKSPACE_SETTINGS[:git][:repo][:base][:url]}/#{oranization}/#{name}.git", tag: version
end
