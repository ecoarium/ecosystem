require 'spec_helper'
require 'smithers'

require 'xmlsimple'
require 'hashdiff'
require 'pp'


describe Smithers::ConfigurationItems::Jobs::Scm::Git do

  it 'should generate basic git configuration' do

    example_credentials_id          = 'example-credentials-id'
    example_git_repo_name           = 'kitchen-sink'
    example_git_organization_name   = 'bbob'
    example_branch_name             = 'next'

    git_scm_xml_block = %^
<scm class="hudson.plugins.git.GitSCM">
  <configVersion>2</configVersion>
  <userRemoteConfigs>
    <hudson.plugins.git.UserRemoteConfig>
      <url>https://github.com/#{example_git_organization_name}/#{example_git_repo_name}.git</url>
      <credentialsId>#{example_credentials_id}</credentialsId>
    </hudson.plugins.git.UserRemoteConfig>
  </userRemoteConfigs>
  <branches>
    <hudson.plugins.git.BranchSpec>
      <name>#{example_branch_name}</name>
    </hudson.plugins.git.BranchSpec>
  </branches>
  <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
  <browser class="hudson.plugins.git.browser.GithubWeb">
    <url>https://github.com</url>
  </browser>
  <submoduleCfg class="list"/>
  <extensions/>
</scm>
^
    expected = XmlSimple.xml_in(git_scm_xml_block, {
      'ForceArray' => false, 'AttrPrefix' => true
    })

    actual = Class.new{
      def configuration
        return @configuration unless @configuration.nil?
        @configuration = {}
      end
    }.new
    Smithers::ConfigurationItems::Jobs::Scm::Git.new(actual){
      credentials_id      example_credentials_id
      repo_name           example_git_repo_name
      organization_name   example_git_organization_name
      branch_name         example_branch_name
    }.configure

    diff = HashDiff.diff(expected, actual.configuration['scm'])

    expect(diff).to eq([])
  end

end
