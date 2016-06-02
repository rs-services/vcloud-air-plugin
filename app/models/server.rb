class Server
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  include ActiveModel::AttributeMethods

  attr_accessor :instance_uuid, :connection, :name, :template, :network,
  :org, :catalog, :vdc,:description, :parent_network

  validates :name, presence: true
  validates :template, presence: true
  validates :network, presence: true
  validates :org, presence: true
  validates :vdc, presence: true
  validates :catalog, presence: true
  validates :connection, presence: true
  validates :description, presence: true

  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  def create
    begin
    orgs = connection.get_organizations
    found_org = connection.get_organization_by_name(@org)
    found_vdc = connection.get_vdc_id_by_name(found_org,@vdc)
    found_catalog = connection.get_catalog_by_name(found_org,@catalog)
    #items = connection.get_catalog_item(found_catalog[@template])
    network_id = connection.get_network_id_by_name(found_org,@parent_network)
    network_config = {name: @name,  fence_mode: 'bridged',
     parent_network: network_id }
     return unless valid?
    connection.create_vapp_from_template(
      found_vdc,
      @name,
      @description,
      "vappTemplate-#{found_catalog[:items][@template]}",
      true,
      network_config)

    rescue => e
      Rails.logger.error e.message
      errors.add(:base, e.message)
    #  return {error: e.message}
    end
  end

private


end