require 'vcloud-rest/connection'
class Server
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  include ActiveModel::AttributeMethods

  attr_accessor :instance_uuid, :connection, :name, :template, :network,
                :org, :catalog, :vdc, :description, :cloud, :server_template,
                :rs_api_refresh_token, :rs_api_host,:deployment

  validates :name, presence: true
  validates :template, presence: true
  validates :network, presence: true
  validates :org, presence: true
  validates :vdc, presence: true
  validates :catalog, presence: true
  validates :description, presence: true
  validates :cloud, presence: true
  validates :rs_api_refresh_token, presence: true
  validates :rs_api_host, presence: true
  validates :server_template, presence: true
  validates :deployment, presence: true

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
    Rails.logger.debug "------- get_organization_by_name(#{@org}) -------"
    found_org = connection.get_organization_by_name(@org)

    Rails.logger.debug "------- get_vdc_id_by_name(#{@found_org},#{@vdc}) -------"
    found_vdc = connection.get_vdc_id_by_name(found_org, @vdc)

    Rails.logger.debug "------- get_catalog_by_name(#{found_org},#{@catalog}) -------"
    found_catalog = connection.get_catalog_by_name(found_org, @catalog)
    Rails.logger.debug "found_catalog #{found_catalog}"

    Rails.logger.debug "------- get_catalog_item_by_name(#{found_catalog[:id]},#{@template}) -------"
    found_catitem = connection.get_catalog_item_by_name(found_catalog[:id], @template)
    Rails.logger.debug "found_catitem #{found_catitem}"

    Rails.logger.debug "------- get_network_id_by_name ---------"
    found_network = connection.get_network_by_name(found_org, network)

    Rails.logger.debug "------- create_vapp_from_template -------"
    vapp = connection.create_vapp_from_template(
      found_vdc,
      name,
      @description,
      "vappTemplate-#{found_catitem[:items][0][:id]}",
      false,
      {fence_mode: 'bridged', name: @network, parent_network: found_network[:id]}
      )
    connection.wait_task_completion(vapp[:task_id])

    #remove vDC non-existant VM Network
     vapp = connection.get_vapp(vapp[:vapp_id])


    Rails.logger.debug "------- get_vapp --------"
    vapp = connection.get_vapp(vapp[:id])
    Rails.logger.debug "vapp: #{vapp}"

    Rails.logger.debug "-------- get_vm ---------"
    vm = connection.get_vm(vapp[:vms_hash][@template][:id])
    Rails.logger.debug "vm: #{vm}"


    Rails.logger.debug "------- add_vm_network --------"
    task_id = connection.add_vm_network(vm[:id],found_network,{fence_mode: 'bridged'})
    connection.wait_task_completion(task_id)

    # rename vm
    Rails.logger.debug "-------- rename_vm ------"
    task_id = connection.rename_vm(vm[:id],name)
    connection.wait_task_completion(task_id)

    # poweron and off to correct network configuration
    # without power cycle eth0 is not activated
    Rails.logger.debug '-------- poweron_vapp ------'
    task_id = connection.poweron_vapp(vapp[:id])
    connection.wait_task_completion(task_id)
    Rails.logger.debug "-------- poweroff_vap ------"
    task_id = connection.poweroff_vapp(vapp[:id])
    connection.wait_task_completion(task_id)
    vapp = connection.get_vapp(vapp[:id])

    # make sure the vapp/vm is stopped
    while vapp[:status]!='stopped' do
      sleep 1
      vapp = connection.get_vapp(vapp[:id])
    end

    # use guest customization to install RL10
    # need to also send new password, otherwise there is no password
    Rails.logger.debug "-------- set_vm_guest_customization ------"
    task_id = connection.set_vm_guest_customization(vm[:id], name,
    {enabled: true, customization_script: script(dns: found_network[:gateway]),
      admin_passwd_enabled: true,admin_passwd: 'right$cale'})
    connection.wait_task_completion(task_id)

    # poweron vapp/vm
    Rails.logger.debug '-------- poweron_vapp ------'
    task_id = connection.poweron_vapp(vapp[:id])
    connection.wait_task_completion(task_id)

    Rails.logger.debug "------- get_vapp --------"
    vapp = connection.get_vapp(vapp[:id])
    Rails.logger.debug "vapp: #{vapp}"
    Rails.logger.debug "vm: #{vm}"
    Rails.logger.debug "------- vApp ID #{vapp[:id]}"

    connection.logout
    vapp
  rescue => e
    Rails.logger.error e.message
    Rails.logger.debug "------- vApp ID #{vapp[:id]}" if vapp
    errors.add(:base, e.message)
  end

  ##
  # find
  def self.find(id)
    connection = Session.create
    Rails.logger.debug '-------- get_vapp ------'
    vapp = connection.get_vapp(id)
    Rails.logger.debug "vapp #{vapp}"
    Rails.logger.debug "vapp.status  == #{vapp[:status]}"
    connection.logout
    vapp
  end

  ##
  # destroy
  def self.destroy(id)
    connection = Session.create
    Rails.logger.debug '-------- get_vapp ------'
    vapp = connection.get_vapp(id)
    Rails.logger.debug "vapp #{vapp}"
    if vapp[:status] == "running"
      Rails.logger.debug '-------- poweroff_vapp ------'
      task_id = connection.poweroff_vapp(id)
      connection.wait_task_completion(task_id)
    end
    while vapp[:status]!='stopped' do
      sleep 1
      vapp = connection.get_vapp(id)
    end
    Rails.logger.debug '-------- delete_vapp ------'
    connection.delete_vapp(id)
    connection.logout
    vapp
  end

  ##
  # stop
  def self.stop(id)
    connection = Session.create
    Rails.logger.debug '-------- get_vapp ------'
    vapp = connection.get_vapp(id)
    Rails.logger.debug "vapp #{vapp}"
    if vapp[:status]=='running'
      Rails.logger.debug '-------- suspend_vapp ------'
      task_id = connection.suspend_vapp(id)
      connection.wait_task_completion(task_id)
    end
    Rails.logger.debug '-------- get_vapp ------'
    vapp = connection.get_vapp(id)
    Rails.logger.debug "vapp #{vapp}"
    Rails.logger.debug "vapp.status  == #{vapp[:status]}"
    connection.logout
    vapp
  end

  ##
  # start
  # :args: String ID
  def self.start(id)
    connection = Session.create
    Rails.logger.debug '-------- get_vapp ------'
    vapp = connection.get_vapp(id)
    Rails.logger.debug "vapp #{vapp}"
    if vapp[:status]=='paused'
      Rails.logger.debug '-------- discard_suspend_state_vapp ------'
      task_id = connection.discard_suspend_state_vapp(id)
      connection.wait_task_completion(task_id)
    end
    Rails.logger.debug '-------- get_vapp ------'
    vapp = connection.get_vapp(id)
    Rails.logger.debug "vapp #{vapp}"
    Rails.logger.debug "vapp.status  == #{vapp[:status]}"
    connection.logout
    vapp
  end

  ##
  # power_on
  # :args: String ID
  def self.power_on(id)
    connection = Session.create
    Rails.logger.debug '-------- get_vapp ------'
    vapp = connection.get_vapp(id)
    Rails.logger.debug "vapp #{vapp}"
    if vapp[:status]=='stopped'
      Rails.logger.debug '-------- poweron_vapp ------'
      task_id = connection.poweron_vapp(id)
      connection.wait_task_completion(task_id)
    end
    Rails.logger.debug '-------- get_vapp ------'
    vapp = connection.get_vapp(id)
    Rails.logger.debug "vapp #{vapp}"
    Rails.logger.debug "vapp.status  == #{vapp[:status]}"
    connection.logout
    vapp
  end

  ##
  # power_off
  # :args: String ID
  def self.power_off(id)
    connection = Session.create
    Rails.logger.debug '-------- get_vapp ------'
    vapp = connection.get_vapp(id)
    Rails.logger.debug "vapp #{vapp}"
    if vapp[:status]=='running'
      Rails.logger.debug '-------- poweroff_vapp ------'
      task_id = connection.poweroff_vapp(id)
      connection.wait_task_completion(task_id)
    end
    Rails.logger.debug '-------- get_vapp ------'
    vapp = connection.get_vapp(id)
    Rails.logger.debug "vapp #{vapp}"
    Rails.logger.debug "vapp.status  == #{vapp[:status]}"
    connection.logout
    vapp
  end

  private
  # rename server to comply with vcloud-air naming.  can not contain spaces
  def name
    @name.gsub(" ","-") if @name
  end

  # run script to enable RL10
  def script(params={})
    cmd = "#!/bin/sh\n"
    cmd << "if [ x$1 == x'postcustomization' ]; then\n"
    cmd << "echo nameserver #{params[:dns]} >> /etc/resolv.conf\n"
    cmd << "echo 'Installing RightLink'\n"
    cmd << "curl -s https://rightlink.rightscale.com/rll/10.4.0/rightlink.enable.sh \
     | bash -s -- -l -k '#{@rs_api_refresh_token}' -t '#{@server_template}' \
     -n '#{@name}' -d '#{@deployment}' -c uca -f #{@cloud} \
     -a '#{@rs_api_host}'\n"
    cmd << "fi\n"
    cmd.encode('utf-8')
  end
end
