class Session
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  include ActiveModel::AttributeMethods

  attr_accessor :host, :username, :password, :org, :api_version

  validates :host, presence: true
  validates :username, presence: true
  validates :password, presence: true
  validates :org, presence: true
  validates :api_version, presence: true

  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  def create
    begin
      connection = VCloudClient::Connection.new(@host, @username, @password, @org, @api_version)
      connection.login
      connection
    rescue => e
      errors.add(:base, e.message)
    end
  end

end
