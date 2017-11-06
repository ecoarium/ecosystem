require 'fileutils'

module CfnDsl
  FileUtils.mkdir_p $WORKSPACE_SETTINGS[:paths][:project][:deploy][:cfndsl][:state] unless File.exist?($WORKSPACE_SETTINGS[:paths][:project][:deploy][:cfndsl][:state])
end
