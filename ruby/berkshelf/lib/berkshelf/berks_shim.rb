Encoding.default_external = "UTF-8"
source "https://supermarket.chef.io"

def override_middle_way_cookbook(name)
  cookbook name, path:  File.expand_path("github/eocarium-cookbooks/#{name}", $WORKSPACE_SETTINGS[:paths][:projects][:root])
end

def middle_way_cookbook(name, version)
  cookbook name, git: "https://github.com/eocarium-cookbooks/#{name}.git", tag: version
end

def cookbook_from_github(oranization, name, version)
  cookbook name, git: "https://github.com/#{oranization}/#{name}.git", tag: version
end
