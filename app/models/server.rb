require 'vcloud-rest/connection'
class Server
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  include ActiveModel::AttributeMethods

  attr_accessor :instance_uuid, :connection, :name, :template, :network,
                :org, :catalog, :vdc, :description

  validates :name, presence: true
  validates :template, presence: true
  validates :network, presence: true
  validates :org, presence: true
  validates :vdc, presence: true
  validates :catalog, presence: true
  validates :description, presence: true

  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  ## server.create
  #
  def create
    raise "missing fields" unless self.valid?
    connection = Session.create
    orgs = connection.get_organizations
    found_org = connection.get_organization_by_name(@org)
    found_vdc = connection.get_vdc_id_by_name(found_org, @vdc)
    found_catalog = connection.get_catalog_by_name(found_org, @catalog)
    found_catitem = connection.get_catalog_item_by_name(found_catalog[:id], @template)
    Rails.logger.debug "------- get_network_id_by_name ---------"
    network_id = connection.get_network_id_by_name(found_org, @network)
    return unless valid?
    Rails.logger.debug "------- create_vapp_from_template -------"
    vapp = connection.create_vapp_from_template(
      found_vdc,
      @name,
      @description,
      "vappTemplate-#{found_catitem[:items][0][:id]}",
      false)
    Rails.logger.debug "------- add_org_network_to_vapp --------"
    connection.wait_task_completion(vapp[:task_id])

    task_id = connection.add_org_network_to_vapp(vapp[:vapp_id], { name: @network,
                                                                   id: network_id },
                                                                   parent_network: { name: @network, id: network_id },
                                                                   fence_mode: 'bridged')
    Rails.logger.debug "------- get_vapp --------"
    vapp = connection.get_vapp(vapp[:vapp_id])
    Rails.logger.debug "-------- get_vm ---------"
    vm = connection.get_vm(vapp[:vms_hash][@template][:id])
    Rails.logger.debug "-------- rename_vm ------"
    task_id = connection.rename_vm(vm[:id],@name)
    connection.wait_task_completion(task_id)
    Rails.logger.debug "-------- set_vm_guest_customization ------"
    task_id = connection.set_vm_guest_customization(vm[:id], @name, {customization_script: script})
    connection.wait_task_completion(task_id)
    Rails.logger.debug "-------- poweron_vm ------"
    connection.poweron_vapp(vapp[:id])
    Rails.logger.debug "------- vApp ID #{vapp[:id]}"
    vapp
  rescue => e
    Rails.logger.error e.message
    errors.add(:base, e.message)
  end

  ##
  # find
  def self.find(id)
    connection = Session.create
    connection.get_vapp(id)
  end

  ##
  # destroy
  def self.destroy(id)
    connection = Session.create
    # Rails.logger.debug '-------- get_organization_by_name ------'
    # found_org = connection.get_organization_by_name(org)
    # Rails.logger.debug '-------- get_vm ------'
    # vm = connection.get_vm(vm_id)
    # Rails.logger.debug '-------- get_vapp_by_name ------'
    # vapp = connection.get_vapp_by_name(found_org, vdc, name)
    # Rails.logger.debug '-------- poweroff_vm ------'
    # task_id = connection.poweroff_vm(vm[:id])
    # connection.wait_task_completion(task_id)
    # Rails.logger.debug '-------- poweroff_vapp ------'
    task_id = connection.poweroff_vapp(id)
    connection.wait_task_completion(task_id)
    Rails.logger.debug '-------- delete_vapp ------'
    connection.delete_vapp(id)
  end


  private

  def script
    "echo 'booting from rightscale'".encode('utf-8')
  end
end
