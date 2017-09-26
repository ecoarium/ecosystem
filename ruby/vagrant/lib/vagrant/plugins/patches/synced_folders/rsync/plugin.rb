loaded_vagrant_gem_path = Gem::Specification.find_by_name('vagrant').gem_dir
require "#{loaded_vagrant_gem_path}/plugins/synced_folders/rsync/plugin"

module VagrantPlugins
  module SyncedFolderRSync
    class Plugin < Vagrant.plugin("2")

      synced_folder("rsync", 6) do
        loaded_vagrant_gem_path = Gem::Specification.find_by_name('vagrant').gem_dir
        require "#{loaded_vagrant_gem_path}/plugins/synced_folders/rsync/synced_folder"
        SyncedFolder
      end

    end
  end
end
