require 'rails_helper'

RSpec.describe Server, type: :model do

let(:vcloud_params){YAML.load_file("#{Rails.root}/config/vcloudair.yml")[Rails.env]}
let(:conn) {conn=VCloudClient::Connection.new(vcloud_params["host"], vcloud_params["username"],
                                vcloud_params["password"], vcloud_params["org"],
                                vcloud_params["api_version"])
                              conn.login}
  it "create " do
    require 'vcloud-rest/connection'
    params={}
    #expect(VCloudClient::Connection).to receive(:new).with("")
    expect_any_instance_of(VCloudClient::Connection).to receive(:create_vapp_from_template).
      with()
    Server.create(params)
  end

end
