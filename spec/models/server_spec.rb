require 'rails_helper'

RSpec.describe Server, type: :model do
  let(:conn){ double('VCloudClient::Connection')}
  let(:org) do
    { catalogs: { 'Telstra_SOE' => '212435e2-2918-4340-a95c-2a053d0019a7',
                  'RHEL-SSD' => '3f036152-a7bc-4964-83c4-69cc895592ef',
                  'PE' => '15008016-1588-4a8d-aaaf-9ab832538449',
                  'RHEL-Standard' => 'ae4616be-0c23-4d5f-b838-f8e36d23969c',
                  'OnRamp' => 'a27f9e11-1dad-4e4b-9a2e-545ffe0a6c3b',
                  'Actifio' => '99afb7ac-c969-4a81-bef1-fead9d9e0548',
                  'Public Catalog' => '578eae17-b0c1-452b-b073-2c6bb1cc3c58',
                  'HomeSite' => '23c7ca16-d98e-44bc-a4a3-7fc3a26fe0d7' },
      vdcs: { 'TelstraTestvdc001' => '33381155-6c6d-46b3-a330-e829617095de' },
      networks: { 'DAVETEST-NET' => '1853896f-3861-4132-b8f0-b15831d3d70e',
                  'OnRampMigrations' => '2162b5fd-5c0b-48a3-a52f-9877689ae4ad',
                  'TelstraTestvdc001-default-routed' => '54ddbd22-8748-412c-b83d-810b5f3a4ce5',
                  'PLC_d10p15-dcn-2506' => '9a443ecb-fea2-4ad4-8741-be36a4877851',
                  'TelstraTestvdc001-default-isolated' => 'e506c761-f6e1-48fd-a30f-a446eff0953a' },
      tasklists: { nil => '9b40b7cb-65b8-4a40-9467-fb6dfa6cebc0' } }
  end
  let(:catalog) do
    { id: '578eae17-b0c1-452b-b073-2c6bb1cc3c58',
      description: 'vCHS service catalog',
      items: { 'W2K12-STD-R2-SQL2K14-WEB' => '1d677048-2b49-434b-98c2-709cf58e00ba',
               'CentOS64-64BIT' => '1f201828-0dd6-40d7-adf5-9e659d802e66' } }
  end
  let(:catitem) do
    { id: '32bf818c-2716-40a6-ae90-2b5f5b6ff907',
      description: 'id: cts-6.4-64bit',
      items: [{ id: '71c3c97e-c329-4883-95f8-86ea45634b76',
                name: 'CentOS64-64BIT',
                vms_hash: { 'CentOS64-64BIT' => { id: '78681b4b-5b00-4e35-8bbe-2b5aed6f4979' } } }] }
  end
  let(:vapp) do
    { id: '19739804-dd6c-4ddd-8faf-8ccd612b9cc6',
      name: 'curt-test-2',
      description: 'my server description',
      status: 'stopped', ip: '1.2.3.4',
      networks: [{ id: '3940bce4-2956-4459-9c17-865dbed7ab2e',
                   name: 'OnRampMigrations', scope: { gateway: '10.209.1.1',
                                                      netmask: '255.255.255.0', fence_mode: 'bridged',
                                                      parent_network: 'OnRampMigrations', retain_network: 'false' } }],
      vapp_snapshot: nil,
      vms_hash: { 'CentOS64-64BIT' => { addresses: [nil], status: 'stopped',
                                        id: '0ea8459b-a869-4079-8fc0-ecdae6d984c6', vapp_scoped_local_id: 'CentOS64-64BIT' } } }
  end
  let(:vm) { {id: '123'} }
  let(:vdc) { org[:vdcs]['TelstraTestvdc001'] }
  let(:orgs) { { 'TelstraTestvdc001' => '9b40b7cb-65b8-4a40-9467-fb6dfa6cebc0' } }
  let(:vcloud_params) { YAML.load_file("#{Rails.root}/config/vcloudair.yml")[Rails.env] }
  let(:found_network) { {id: '12345abc'} }
  let(:params) do
    { org: 'TelstraTestvdc001',
      vdc: 'TelstraTestvdc001',
      template: 'CentOS64-64BIT',
      catalog: 'Public Catalog',
      network: 'TelstraTestvdc001',
      name: 'myvapp-name',
      description: 'myvapp description',
      deployment: 'my deployment',
      server_template: 'my server_template',
      cloud: 'vCloudPOC',
      rs_api_host: 'us-4.rightscale.com',
      rs_api_refresh_token: 'mytoken'
    }
  end
  it 'create vapp' do
    conn = double('VCloudClient::Connection')
    expect(conn).to receive(:get_organizations).and_return(orgs)
    expect(conn).to receive(:get_organization_by_name).with(params[:org])
      .and_return(org)

    expect(conn).to receive(:get_vdc_id_by_name).with(org, params[:vdc])
      .and_return('33381155-6c6d-46b3-a330-e829617095de')

    expect(conn).to receive(:get_catalog_by_name).with(org, params[:catalog])
      .and_return(catalog)

    expect(conn).to receive(:get_catalog_item_by_name).with(catalog[:id],
                                                            params[:template]).and_return(catitem)

    expect(conn).to receive(:get_network_by_name).with(org, params[:network])
      .and_return(found_network)

    expect(conn).to receive(:create_vapp_from_template)
      .with(vdc, params[:name], params[:description],
            "vappTemplate-#{catitem[:items][0][:id]}", false,
            {fence_mode: 'bridged', name: params[:network], parent_network: found_network[:id]})
      .and_return(vapp_id: vapp[:id], task_id: '1')

    expect(conn).to receive(:wait_task_completion).with("1").exactly(7).times

    expect(conn).to receive(:get_vapp).with(vapp[:id])
      .and_return(vapp).exactly(4).times

    expect(conn).to receive(:rename_vm).with(vm[:id],params[:name]).
      and_return('1')

    expect(conn).to receive(:set_vm_guest_customization).with(vm[:id], params[:name],
    {enabled: true, customization_script: /Installing RightLink/,
      admin_passwd_enabled: true,admin_passwd: 'right$cale'}).and_return('1')

    expect(conn).to receive(:poweron_vapp).with(vapp[:id]).and_return('1').
      exactly(2).times
    expect(conn).to receive(:poweroff_vapp).with(vapp[:id]).and_return('1')
    expect(conn).to receive(:add_vm_network).with(vm[:id],found_network,
      {fence_mode: 'bridged'}).and_return('1')

    expect(conn).to receive(:get_vm).with(vapp[:vms_hash][params[:template]][:id])
      .and_return(vm)
    expect(conn).to receive(:logout)
    expect(Session).to receive(:create).and_return(conn)
    server = Server.new(params)
    expect(server.create).to eq(vapp)
  end

  it 'create returns error' do
    conn = double('VCloudClient::Connection')
    expect(conn).to receive(:get_organizations).and_return(orgs)
      .and_raise(RuntimeError, 'failed')
    expect(Session).to receive(:create).and_return(conn)
    server = Server.new(params)
    server.create
    expect(server.errors.full_messages).to include 'failed'
  end

  it 'invalid server' do
    server = Server.new
    expect(server.valid?).to eq false
    server.create
    expect(server.errors).to include :network
  end

  it "destroy server" do
    vapp.merge!(status: 'stopped')
    expect(conn).to receive(:get_vapp).with(vapp[:id]).and_return(vapp)
    #expect(conn).to receive(:poweroff_vapp).with(vapp[:id]).and_return('1')
    expect(conn).to receive(:delete_vapp).with(vapp[:id]).and_return('1')
    #expect(conn).to receive(:wait_task_completion).with("1").exactly(1).times
    expect(conn).to receive(:logout)
    expect(Session).to receive(:create).and_return(conn)
    Server.destroy(vapp[:id])
  end

  it "find server" do
    expect(Session).to receive(:create).and_return(conn)
    expect(conn).to receive(:get_vapp).with('123').and_return(vapp)
    expect(conn).to receive(:logout)
    Server.find('123')
  end

  it "stop server" do
    vapp.merge!(status: 'running')
    expect(Session).to receive(:create).and_return(conn)
    expect(conn).to receive(:get_vapp).with('123').exactly(2).times.and_return(vapp)
    expect(conn).to receive(:suspend_vapp).with('123').and_return("1")
    expect(conn).to receive(:wait_task_completion).with("1").exactly(1).times
    expect(conn).to receive(:logout)
    Server.stop('123')
  end

  it "start server" do
    vapp.merge!(status: 'paused')
    expect(Session).to receive(:create).and_return(conn)
    expect(conn).to receive(:get_vapp).with('123').exactly(2).times.and_return(vapp)
    expect(conn).to receive(:discard_suspend_state_vapp).with('123').and_return("1")
    expect(conn).to receive(:wait_task_completion).with("1").exactly(1).times
    expect(conn).to receive(:logout)
    Server.start('123')
  end

  it "power_off server" do
    vapp.merge!(status: 'running')
    expect(Session).to receive(:create).and_return(conn)
    expect(conn).to receive(:get_vapp).with('123').exactly(2).times.and_return(vapp)
    expect(conn).to receive(:poweroff_vapp).with('123').and_return("1")
    expect(conn).to receive(:wait_task_completion).with("1").exactly(1).times
    expect(conn).to receive(:logout)
    Server.power_off('123')
  end

  it "power_on server" do
    vapp.merge!(status: 'stopped')
    expect(Session).to receive(:create).and_return(conn)
    expect(conn).to receive(:get_vapp).with('123').exactly(2).times.and_return(vapp)
    expect(conn).to receive(:poweron_vapp).with('123').and_return("1")
    expect(conn).to receive(:wait_task_completion).with("1").exactly(1).times
    expect(conn).to receive(:logout)
    Server.power_on('123')
  end
end
