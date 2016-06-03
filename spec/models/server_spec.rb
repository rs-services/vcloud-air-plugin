require 'rails_helper'

RSpec.describe Server, type: :model do
  let(:org){{:catalogs=>{"Telstra_SOE"=>"212435e2-2918-4340-a95c-2a053d0019a7",
    "RHEL-SSD"=>"3f036152-a7bc-4964-83c4-69cc895592ef",
    "PE"=>"15008016-1588-4a8d-aaaf-9ab832538449",
    "RHEL-Standard"=>"ae4616be-0c23-4d5f-b838-f8e36d23969c",
    "OnRamp"=>"a27f9e11-1dad-4e4b-9a2e-545ffe0a6c3b",
    "Actifio"=>"99afb7ac-c969-4a81-bef1-fead9d9e0548",
    "Public Catalog"=>"578eae17-b0c1-452b-b073-2c6bb1cc3c58",
    "HomeSite"=>"23c7ca16-d98e-44bc-a4a3-7fc3a26fe0d7"},
    :vdcs=>{"TelstraTestvdc001"=>"33381155-6c6d-46b3-a330-e829617095de"},
    :networks=>{"DAVETEST-NET"=>"1853896f-3861-4132-b8f0-b15831d3d70e",
      "OnRampMigrations"=>"2162b5fd-5c0b-48a3-a52f-9877689ae4ad",
      "TelstraTestvdc001-default-routed"=>"54ddbd22-8748-412c-b83d-810b5f3a4ce5",
      "PLC_d10p15-dcn-2506"=>"9a443ecb-fea2-4ad4-8741-be36a4877851",
      "TelstraTestvdc001-default-isolated"=>"e506c761-f6e1-48fd-a30f-a446eff0953a"},
      :tasklists=>{nil=>"9b40b7cb-65b8-4a40-9467-fb6dfa6cebc0"}}}
  let(:catalog){{:id=>"578eae17-b0c1-452b-b073-2c6bb1cc3c58",
    :description=>"vCHS service catalog",
    :items=>{"W2K12-STD-R2-SQL2K14-WEB"=>"1d677048-2b49-434b-98c2-709cf58e00ba",
    "CentOS64-64BIT"=>"1f201828-0dd6-40d7-adf5-9e659d802e66"}}}
  let(:catitem){{:id=>"32bf818c-2716-40a6-ae90-2b5f5b6ff907",
    :description=>"id: cts-6.4-64bit",
    :items=>[{:id=>"71c3c97e-c329-4883-95f8-86ea45634b76",
      :name=>"CentOS64-64BIT",
      :vms_hash=>{"CentOS64-64BIT"=>{:id=>"78681b4b-5b00-4e35-8bbe-2b5aed6f4979"}}}]}}
  let(:vdc){org[:vdcs]["TelstraTestvdc001"]}
  let(:orgs){{"TelstraTestvdc001"=>"9b40b7cb-65b8-4a40-9467-fb6dfa6cebc0"}}
  let(:vcloud_params) { YAML.load_file("#{Rails.root}/config/vcloudair.yml")[Rails.env] }
  let(:params){{org: 'TelstraTestvdc001',
    vdc: "TelstraTestvdc001",
    template: 'CentOS64-64BIT',
    catalog: 'Public Catalog',
    parent_network: 'OnRampMigrations',
    network: "TelstraTestvdc001",
    name: 'myvapp-name',
    description: 'myvapp description'}
  }
  let(:network_config){{name: params[:network],fence_mode: 'bridged',
    parent_network: "2162b5fd-5c0b-48a3-a52f-9877689ae4ad"}}

  it 'create vapp' do
    conn = double('VCloudClient::Connection')
    expect(conn).to receive(:get_organizations).and_return(orgs)
    expect(conn).to receive(:get_organization_by_name).with(params[:org]).
      and_return(org)

    expect(conn).to receive(:get_vdc_id_by_name).with(org,params[:vdc]).
      and_return("33381155-6c6d-46b3-a330-e829617095de")

    expect(conn).to receive(:get_catalog_by_name).with(org,params[:catalog]).
        and_return(catalog)

    expect(conn).to receive(:get_catalog_item_by_name).with(catalog[:id],
    params[:template]).and_return(catitem)

    expect(conn).to receive(:get_network_id_by_name).with(org,params[:parent_network]).
            and_return("2162b5fd-5c0b-48a3-a52f-9877689ae4ad")

    expect(conn).to receive(:create_vapp_from_template).
      with(vdc, params[:name], params[:description],
              "vappTemplate-#{catitem[:items][0][:id]}", true, network_config).
      and_return(vapp_id: '123', task_id: '1')

    server = Server.new(params.merge(connection: conn))
    expect(server.create()).to eq({vapp_id: '123', task_id: '1'})
  end

  it 'create returns error' do
    conn = double('VCloudClient::Connection')
    expect(conn).to receive(:get_organizations).and_return(orgs).
        and_raise(RuntimeError,"failed")
    server = Server.new(params.merge(connection: conn))
    server.create
    expect(server.errors.full_messages).to include "failed"
  end

  it 'invalid server' do
    server = Server.new()
    expect(server.valid?).to eq false
    server.create
    expect(server.errors).to include :network
  end
end
