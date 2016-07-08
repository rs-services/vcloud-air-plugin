require 'rails_helper'

RSpec.describe ServersController, type: :controller do

before{
  config = YAML.load_file("#{Rails.root}/config/vcloudair.yml")[Rails.env]
  request.headers["X-Api-Shared-Secret"]=config["api-shared-secret"]
}

  let(:create_params) {
    { org: 'TelstraTestvdc001',
      vdc: 'TelstraTestvdc001',
      template: 'CentOS64-64BIT',
      catalog: 'Public Catalog',
      parent_network: 'OnRampMigrations',
      network: 'TelstraTestvdc001',
      name: 'myvapp-name',
      description: 'myvapp description',
      platform: 'linux'}
    }
  let(:destroy_params) {
    { vapp_id: '123'}
    }
    let(:vapp){{id:"976faacd-baf9-4505-a7c3-2e09abad3858",
      vm_name:"CentOS64-64BIT",
      status:"stopped",href:"/plugin/servers/976faacd-baf9-4505-a7c3-2e09abad3858"}}

  it 'create server' do
    server = double("Server")
    expect(Server).to receive(:new).with(create_params).
      and_return(server)
    expect(server).to receive(:create).and_return({id: 'abc',task_id: '123'})
    post :create, {server: create_params}
    expect(response).to be_successful
    expect(response.headers["Content-Type"]).to eq "application/vnd.vcloudair.servers+json"
    expect(response.headers["Location"]).to eq(server_path('abc') )
    expect(response.body).to eq({id: 'abc',
      task_id: '123',
      href: server_path("abc")}.to_json)
  end

  it 'create failed with error' do
    server = double("Server")
    expect(Server).to receive(:new).with(create_params).
      and_return(server)
    expect(server).to receive(:create).and_raise(RuntimeError,"failed")
    post :create , {server: create_params}
    expect(response).to_not be_successful
    expect(response.body).to eq "failed"
  end

  it 'destroy' do
    expect(Server).to receive(:destroy).with('123').
      and_return({task_id: '1'})
    post :destroy, {id: '123'}
    expect(response).to be_successful
    expect(response.body).to eq({task_id: '1'}.to_json)
  end

  it "show" do
    server = double(Server)
    expect(Server).to receive(:find).with(vapp[:id]).
      and_return(vapp)
    post :show, {id: vapp[:id]}
    expect(response).to be_successful
    expect(response.headers["Content-Type"]).to include "application/vnd.vcloudair.servers+json"
    expect(response.body).to eq(vapp.to_json)
  end

  it "show with error" do
    server = double(Server)
    expect(Server).to receive(:find).with('987').
      and_raise(RuntimeError,"failed")
    post :show, {id: '987'}
    expect(response).to_not be_successful
    expect(response.body).to eq "failed"
  end

  it "stop" do
    server = double(Server)
    expect(Server).to receive(:stop).with(vapp[:id]).
      and_return(vapp)
    post :stop, {id: vapp[:id]}
    expect(response).to be_successful
    expect(response.headers["Content-Type"]).to include "application/vnd.vcloudair.servers+json"
    expect(response.body).to eq(vapp.to_json)
  end

  it "start" do
    server = double(Server)
    expect(Server).to receive(:start).with(vapp[:id]).
      and_return(vapp)
    post :start, {id: vapp[:id]}
    expect(response).to be_successful
    expect(response.headers["Content-Type"]).to include "application/vnd.vcloudair.servers+json"
    expect(response.body).to eq(vapp.to_json)
  end

  it "power_off" do
    server = double(Server)
    expect(Server).to receive(:power_off).with(vapp[:id]).
      and_return(vapp)
    post :power_off, {id: vapp[:id]}
    expect(response).to be_successful
    expect(response.headers["Content-Type"]).to include "application/vnd.vcloudair.servers+json"
    expect(response.body).to eq(vapp.to_json)
  end

  it "power_on" do
    server = double(Server)
    expect(Server).to receive(:power_on).with(vapp[:id]).
      and_return(vapp)
    post :power_on, {id: vapp[:id]}
    expect(response).to be_successful
    expect(response.headers["Content-Type"]).to include "application/vnd.vcloudair.servers+json"
    expect(response.body).to eq(vapp.to_json)
  end

end
