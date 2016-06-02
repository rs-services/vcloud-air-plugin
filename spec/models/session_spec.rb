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
    session = Session.new(vcloud_params)
    expect(session.create).to eq(conn)
  end

  it 'create session failed' do
    conn = double('VCloudClient::Connection')
    expect(VCloudClient::Connection).to receive(:new)
      .with(vcloud_params['host'],
            vcloud_params['username'],
            vcloud_params['password'], vcloud_params['org'],
            vcloud_params['api_version']).and_raise(RuntimeError, 'failed')
    session = Session.new(vcloud_params)
    session.create
    expect(session.errors.full_messages).to include 'failed'
  end

  it 'invalid session' do
    session = Session.new
    expect(session.valid?).to eq false
    session.create
    expect(session.errors).to include :host
  end
end
