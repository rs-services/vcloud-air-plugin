class Server
    include ActiveModel::Validations
    include ActiveModel::Conversion
    extend ActiveModel::Naming
    include ActiveModel::AttributeMethods

    attr_accessor :instance_uuid, :name, :template, :network

    validates :name, presence: true
    validates :template, presence: true
    validates :network, presence: true

    def initialize(attributes = {})
        attributes.each do |name, value|
            send("#{name}=", value)
        end
    end

    def self.create()
      require 'vcloud-rest/connection'
      conn = VCloudClient::Connection.new("https://p15v4-vcd.vchs.vmware.com",
      "curt@rightscale.com",
      "My$m2fsx",
      "TelstraTestvdc001",
      "5.6")
      conn.login
      id = conn.get_catalog_id_by_name("foobar")
      #conn.create_vapp_from_template()
    end
end
