require 'vcloud-rest/connection'
class Session
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  include ActiveModel::AttributeMethods

  def self.create
    begin

      config = YAML.load_file("#{Rails.root}/config/vcloudair.yml")[Rails.env]
      if config["logging"]
        ENV["VCLOUD_REST_DEBUG_LEVEL"]=config["logging"]
      end
      connection = VCloudClient::Connection.new(config["host"], config["username"],
      config["password"], config["org"], config["api_version"])
      connection.login
      connection
    rescue => e
      "Error: #{e.message}"
    end
  end

end
