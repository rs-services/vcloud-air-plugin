require 'vcloud-rest/connection'
class Server
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  include ActiveModel::AttributeMethods

  attr_accessor :name, :template, :network,
                :org, :catalog, :vdc, :description, :cloud, :server_template,
                :rs_api_refresh_token, :rs_api_host,:deployment, :platform

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
  validates :platform, presence: true

  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  ## server.create
  #
  def create
    raise errors.full_messages unless self.valid?
    @connection = Session.create
    orgs = @connection.get_organizations
    Rails.logger.debug "------- get_organization_by_name(#{@org}) -------"
    found_org = @connection.get_organization_by_name(@org)

    Rails.logger.debug "------- get_vdc_id_by_name(#{@found_org},#{@vdc}) -------"
    found_vdc = @connection.get_vdc_id_by_name(found_org, @vdc)

    Rails.logger.debug "------- get_catalog_by_name(#{found_org},#{@catalog}) -------"
    found_catalog = @connection.get_catalog_by_name(found_org, @catalog)
    Rails.logger.debug "found_catalog #{found_catalog}"

    Rails.logger.debug "------- get_catalog_item_by_name(#{found_catalog[:id]},#{@template}) -------"
    found_catitem = @connection.get_catalog_item_by_name(found_catalog[:id], @template)
    Rails.logger.debug "found_catitem #{found_catitem}"

    Rails.logger.debug "------- get_network_id_by_name ---------"
    found_network = @connection.get_network_by_name(found_org, network)

    Rails.logger.debug "------- create_vapp_from_template -------"
    vapp = @connection.create_vapp_from_template(
      found_vdc,
      name,
      @description,
      "vappTemplate-#{found_catitem[:items][0][:id]}",
      false,
      {fence_mode: 'bridged', name: @network, parent_network: found_network[:id]}
      )
    @connection.wait_task_completion(vapp[:task_id])

    Rails.logger.debug "------- get_vapp --------"
    vapp = @connection.get_vapp(vapp[:vapp_id])
    #wait for vapp to be stopped
    wait(vapp,"stopped")
    Rails.logger.debug "vapp: #{vapp}"

    Rails.logger.debug "-------- get_vm ---------"
    vm = @connection.get_vm(vapp[:vms_hash][@template][:id])
    Rails.logger.debug "vm: #{vm}"

    Rails.logger.debug "-------- add_vm_network --------"
    task_id = @connection.add_vm_network(vm[:id],found_network,{fence_mode: 'bridged'})
    @connection.wait_task_completion(task_id)

    # rename vm
    Rails.logger.debug "-------- rename_vm ------"
    task_id = @connection.rename_vm(vm[:id],name)
    @connection.wait_task_completion(task_id)

    # poweron and off to correct network configuration
    # without power cycle eth0 is not activated
    Rails.logger.debug '-------- poweron_vapp ------'
    task_id = @connection.poweron_vapp(vapp[:id])
    @connection.wait_task_completion(task_id)
    # wait for vapp to be running
    wait(vapp, "running")

    Rails.logger.debug "-------- poweroff_vapp ------"
    task_id = @connection.poweroff_vapp(vapp[:id])
    @connection.wait_task_completion(task_id)
    # wait for vapp to be stopped
    wait(vapp, "stopped")

    Rails.logger.debug "-------- set_vm_guest_customization ------"
    # use guest customization to install RL10
    # need to also send new password, otherwise there is no password
    task_id = @connection.set_vm_guest_customization(vm[:id], name,
    {enabled: true, customization_script: script(),
      admin_passwd_enabled: true,admin_passwd: 'Right$cale'})
    @connection.wait_task_completion(task_id)

    # poweron vapp/vm
    Rails.logger.debug '-------- poweron_vapp ------'
    task_id = @connection.poweron_vapp(vapp[:id])
    @connection.wait_task_completion(task_id)
    wait(vapp,"running")

    Rails.logger.debug "------- get_vapp --------"
    vapp = @connection.get_vapp(vapp[:id])
    Rails.logger.debug "vapp: #{vapp}"
    Rails.logger.debug "vm: #{vm}"
    Rails.logger.info "------- vApp ID #{vapp[:id]}"
    @connection.logout
    vapp
    rescue => e
      Rails.logger.error e.message
      Rails.logger.info "------- vApp ID #{vapp[:id]}" if vapp
      errors.add(:base, e.message)
      # if vapp[:status]=='running'
      #   Rails.logger.debug "-------- poweroff_vapp ------"
      #   task_id = @connection.poweroff_vapp(vapp[:id])
      #   @connection.wait_task_completion(task_id)
      #   # wait for vapp to be stopped
      #   wait(vapp, "stopped")
      # end
      # Rails.logger.debug "-------- poweroff_vapp ------"
      # @connection.delete_vapp(vapp[:id])
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
    @connection = Session.create
    Rails.logger.debug '-------- get_vapp ------'
    vapp = @connection.get_vapp(id)
    Rails.logger.debug "vapp #{vapp}"
    if vapp[:status] == "running"
      Rails.logger.debug '-------- poweroff_vapp ------'
      task_id = @connection.poweroff_vapp(id)
      @connection.wait_task_completion(task_id)
    end
    send(:wait,vapp,"stopped")
    Rails.logger.debug '-------- delete_vapp ------'
    begin
      @connection.delete_vapp(id)
    rescue => e
      # sometimes the poweroff_vapp doesn't work and the vapp becomes
      # only partially stopped.  this rescue trys another poweroff and delete
      Rails.logger.debug "ERROR: #{e.message}"
      if e.message =~ /running/
        Rails.logger.debug '-------- retrying poweroff_vapp and delete ------'
        task_id = @connection.poweroff_vapp(id)
        @connection.wait_task_completion(task_id)
        @connection.delete_vapp(id)
      end
    end
    @connection.logout
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

  def self.wait(vapp,status)
    server = Server.new
    server.send(:wait, vapp, status)
  end
  # wait for vapp to change status
  # expect vapp[:status] to match status before continuing
  def wait(vapp,status)
    while vapp[:status] != status do
      Rails.logger.debug "waiting... vapp status: #{vapp[:status]}"
      sleep 1
      vapp = @connection.get_vapp(vapp[:id])
    end
  end

  # rename server to comply with vcloud-air naming conventions,
  # can not contain spaces
  def name
    @name.gsub(" ","-") if @name
  end

  def script(params={})
    case @platform.downcase
    when "linux"
      linux_script(params)
    when "windows"
      windows_script(params)
    end
  end
  # run script to enable RL10 for linux
  def linux_script(params={})
    cmd = %{#!/bin/sh
      if [ x$1 = x'postcustomization' ]; then
        echo 'Installing RightLink'
        curl -s https://rightlink.rightscale.com/rll/10/rightlink.enable.sh \
     | bash -s -- -l -k '#{@rs_api_refresh_token}' -t '#{@server_template}' \
     -n '#{@name}' -d '#{@deployment}' -c uca -f #{@cloud} \
     -a '#{@rs_api_host}'
     fi}
    cmd.encode('utf-8')
  end

  # run script to enable RL10 for windows
  def windows_script(params={})
    cmd = %{@echo off\n\r
if “%1%” == “postcustomization” (\n\r
echo Installing RightLink\n\r
powershell -Command "(New-Object Net.WebClient).DownloadFile('https://rightlink.rightscale.com/rll/10/rightlink.enable.ps1', 'rightlink.enable.ps1')"\n\r
Powershell -ExecutionPolicy Unrestricted -File rightlink.enable.ps1  -refreshToken  #{@rs_api_refresh_token} -serverTemplateName "#{@server_template}"   -ServerName #{@name} -deploymentName #{@deployment} -cloudType uca  -ApiServer #{@rs_api_host}\n\r
)}
cmd.encode('utf-8')
  end

end
