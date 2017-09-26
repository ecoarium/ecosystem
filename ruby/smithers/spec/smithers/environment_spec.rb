require 'spec_helper'
require 'smithers'

describe Smithers::Environment do

  it 'should return a relative path to the jenkins properties file' do
    expected = 'jenkins/.build/down_stream_job_properties_file'

    actual = Smithers::Environment.down_stream_job_properties_file_path
    expect(actual).to eq(expected)
  end

end