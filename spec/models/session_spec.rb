require 'rails_helper'
require 'vcloud-rest/connection'

RSpec.describe Session, type: :model do
  let(:vcloud_params) { YAML.load_file("#{Rails.root}/config/vcloudair.yml")[Rails.env] }

  it 'create session' do
    conn = double('VCloudClient::Connection')
    expect(VCloudClient::Connection).to receive(:new)
      .with(vcloud_params['host'],
            vcloud_params['username'],
            vcloud_params['password'], vcloud_params['org'],
            vcloud_params['api_version']).and_return(conn)
    expect(conn).to receive(:login)
    session = Session.create
    expect(session).to eq(conn)
  end

  it 'create session failed' do
    expect(VCloudClient::Connection).to receive(:new)
      .with(vcloud_params['host'],
            vcloud_params['username'],
            vcloud_params['password'], vcloud_params['org'],
            vcloud_params['api_version']).and_raise(RuntimeError, 'failed')
    session = Session.create
    expect(session).to eq('Error: failed')

  end
end
