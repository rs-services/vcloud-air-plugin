require 'rails_helper'

RSpec.describe ServersController, type: :controller do
  let(:session_params) {
    { host: 'http://test',
      username: 'user@example.com',
      password: 'mypassword',
      org: 'TelstraTestvdc001',
      api_version: '5.6' }
  }
  let(:create_params) {
    { org: 'TelstraTestvdc001',
      vdc: 'TelstraTestvdc001',
      template: 'CentOS64-64BIT',
      catalog: 'Public Catalog',
      parent_network: 'OnRampMigrations',
      network: 'TelstraTestvdc001',
      name: 'myvapp-name',
      description: 'myvapp description'
  }
}

  it 'create server' do
    conn = double('VCloudClient::Connection')
    session = double(Session, errors:[])
    server = double(Server)
    expect(Session).to receive(:new).with(session_params).and_return(session)
    expect(session).to receive(:create).and_return(conn)
    expect(Server).to receive(:new).with(create_params.merge(connection: conn)).
    and_return(server)
    expect(server).to receive(:create).and_return({vapp_id: 'abc',task_id: '123'})
    post :create, {session: session_params, server: create_params}
    expect(response).to be_successful
    expect(response.body).to eq({vapp_id: 'abc',task_id: '123'}.to_json)
  end

  it 'create failed with error' do
    conn = double('VCloudClient::Connection')
    session = double(Session, error: ['failed'])
    expect(Session).to receive(:new).with(session_params).and_return(session)
    expect(session).to receive(:create).and_raise(RuntimeError,"failed")
    post :create , {session: session_params, server: create_params}
    expect(response).to_not be_successful
    expect(response.body).to eq "failed"
  end
end
