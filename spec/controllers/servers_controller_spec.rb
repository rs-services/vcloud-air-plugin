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
      description: 'myvapp description'}
    }
  let(:destroy_params) {
    { org: 'TelstraTestvdc001',
      vdc: 'TelstraTestvdc001',
      name: 'myvapp-name',
      vm_id: '123'}
    }
    let(:vm){{id:"976faacd-baf9-4505-a7c3-2e09abad3858",
      vm_name:"CentOS64-64BIT",
      status:"stopped",href:"http://1d19b734.ngrok.io/plugin/servers/976faacd-baf9-4505-a7c3-2e09abad3858"}}

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
    expect(response.headers["Content-Type"]).to include "application/vnd.vcloudair.servers+json"
    expect(response.body).to eq({vapp_id: 'abc',
      task_id: '123',
      href:"http://test.host/plugin/servers/"}.to_json)
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

  it 'destroy' do
    conn = double('VCloudClient::Connection')
    session = double(Session, errors:[])
    server = double(Server)
    expect(Session).to receive(:new).with(session_params).and_return(session)
    expect(session).to receive(:create).and_return(conn)
    expect(Server).to receive(:destroy).with(conn,destroy_params[:org],
      destroy_params[:vdc],destroy_params[:name],destroy_params[:vm_id]).
      and_return({task_id: '1'})
    post :destroy, {session: session_params, id: destroy_params[:vm_id], server: destroy_params}
    expect(response).to be_successful
    expect(response.headers["Content-Type"]).to include "application/vnd.vcloudair.servers+json"
    expect(response.body).to eq({task_id: '1'}.to_json)
  end

  it "show" do
    conn = double('VCloudClient::Connection')
    session = double(Session, errors:[])
    server = double(Server)
    expect(Session).to receive(:new).with(session_params).and_return(session)
    expect(session).to receive(:create).and_return(conn)
    expect(Server).to receive(:find).with(conn,vm[:id]).
      and_return(vm)
    post :show, {session: session_params, id: vm[:id]}
    expect(response).to be_successful
    expect(response.headers["Content-Type"]).to include "application/vnd.vcloudair.servers+json"
    expect(response.body).to eq(vm.to_json)
  end

  it "show with error" do
    conn = double('VCloudClient::Connection')
    session = double(Session, errors:[])
    server = double(Server)
    expect(Session).to receive(:new).with(session_params).and_return(session)
    expect(session).to receive(:create).and_return(conn)
    expect(Server).to receive(:find).with(conn,'987').
      and_raise(RuntimeError,"failed")
    post :show, {session: session_params, id: '987'}
    expect(response).to_not be_successful
    expect(response.body).to eq "failed"
  end

end
