name "vclould air plugin"
rs_ca_ver 20131202
short_description "vcloud-air plugin"

parameter "network" do
  type "list"
  label "Network"
  description "Select the network to launch into"
  allowed_values "TELSTRATESTVDC001-DEFAULT-ROUTED", "DAVETEST-NET","OnRampMigrations","TELSTRATESTVDC001-DEFAULT-ISOLATED"
  default "OnRampMigrations"
  operations "launch"
end

parameter "os" do
  type "list"
  label "Operating System"
  description "Select the OS to boot"
  allowed_values "CentOS", "Ubuntu", "Windows"
  default "CentOS"
  operations "launch"
end

mapping "os_mapping" do
  {
    "CentOS" => {
      "image" => "CentOS64-64BIT",
    },
    "Ubuntu" => {
      "image" => "Ubuntu Server 12.04 LTS (amd64 20150127)",
    },
    "Windows" => {
      "image" => "W2K12-STD-64BIT",
    },
  }
end


resource "vapp", type: "vcloudair.server" do
  org "TelstraTestvdc001"                   # the vcloudair organization
  name "Server 1"                           # the vapp name
  vdc "TelstraTestvdc001"                   # the virtual data center  for the vapp
  network $network                          # the network(s) to place the vApp
  template map($os_mapping, $os, 'image')   # the template to build the vApp
  catalog "Public Catalog"                  # The catalog where to find the template
  description "My vApp from SelfService"    # The description of the vApp
  cloud "vCloudPOC"                         # name of the UCA cloud
  server_template "RightScale UCA base"     # ServerTemplate Name
  deployment @@deployment.name
end

namespace "vcloudair" do
  service do
    host "http://d33297d9.ngrok.io" # HTTP endpoint presenting an API defined by self-serviceto act on resources
    path "/plugin"  # path prefix for all resources, RightScale account_id substituted in for multi-tenancy
    headers do {
      "user-agent" => "self_service" ,          # special headers as needed
      "X-Api-Shared-Secret" => "theapisecret"  #change this key to match api-shared-secret plugin config/vcloudair.yml file
    } end
  end

  type "server" do               # define the resource name.  should match controller in plugin backend
    provision "provision_vapp"   # name of RCL definition to use to create/provision the resource
    delete  "delete_vapp"        # name of RCL definition to use to delete the resource
    fields do
      field "name" do
        type "string"
        required true
      end
      field "org" do
        type "string"
        required true
      end
      field "vdc" do
        type "string"
        required true
      end
      field "network" do
        type "string"
        required true
      end
      field "template" do
        type "string"
        required true
      end
      field "catalog" do
        type "string"
        required true
      end
      field "description" do
        type "string"
        required true
      end
      field "cloud" do
        type "string"
        required true
      end
      field "server_template" do
        type "string"
        required true
      end
      field "rs_api_refresh_token" do
        type "string"
        required false
      end
      field "rs_api_host" do
        type "string"
        required false
      end
      field "deployment" do
        type "string"
        required true
      end
    end
  end
end

# create new server, and return it's resoruce
define provision_vapp(@raw_server) return @vapp do
  call getCredential("RS_API_REFRESH_TOKEN") retrieve $refresh_token
  call find_shard(@@deployment) retrieve $shard_number
  @vapp = vcloudair.server.create({
    server:{
    org: @raw_server.org,
    name: @raw_server.name,
    vdc: @raw_server.vdc,
    network: @raw_server.network,
    template: @raw_server.template,
    catalog: @raw_server.catalog,
    description: @raw_server.description,
    cloud: @raw_server.cloud,
    deployment: @raw_server.deployment,
    server_template: @raw_server.server_template,
    rs_api_refresh_token: $refresh_token,
    rs_api_host: join(["us-",$shard_number,".rightscale.com"])
  }
   })
   $server_object = to_object(@vapp)
   call sys_log("server created",to_s($server))
end

# delete the server and return the resource
# first find all the servers in RS CM
# issue terminate action to remove the server objects
# wait until they are all terminated
# delete the vapp last
define delete_vapp(@vapp) return @vapp do
  @servers = rs.servers.get(filter: [join(["deployment_href==",@@deployment.href])])
  @servers.terminate()
  sub timeout: 5m do
    sleep_until(all?(@servers.state[], "inactive"))
  end
  @vapp.destroy()
end

output 'server_status' do
  label "Current Status"
  category "Connect"
  default_value $status
  description "Server status"
end

output 'server_ip' do
  label "IP Address"
  category "Connect"
  default_value $ip
  description "Server IP Address"
end

#########
# Operation
#########

operation "launch" do
  description 'Launch the application'
  definition 'launch_handler'
  output_mappings do {
    $server_status => $status,
    $server_ip => $ip
  } end
end

operation "Stop Server" do
  definition           "do_stop"
  description          "suspend_vapp the server from running state."
  output_mappings do {
    $server_status => $status,
    $server_ip => $ip
    } end
end

operation "Start Server" do
  definition           "do_start"
  description          "Start the server from suspended state"
  output_mappings do {
    $server_status => $status,
    $server_ip => $ip
    } end
end

operation "Power Off Server" do
  definition           "do_power_off"
  description          "Power off a running server"
  output_mappings do {
      $server_status => $status,
      $server_ip => $ip
    } end
end

operation "Power On Server" do
  definition           "do_power_on"
  description          "Power on a stopped/powered off server"
  output_mappings do {
    $server_status => $status,
    $server_ip => $ip
    } end
end

#########
# RCL
#########
# provision the server
# return values for output mappings
define launch_handler(@vapp) return @vapp, $status, $ip do

  provision(@vapp)

  $vapp_object = to_object(@vapp)
  $status = $vapp_object["details"][0]["status"]
  $ip = $vapp_object["details"][0]["ip"]
  call sys_log("server launched",to_s($server))
end

# stop server from running state
define do_stop(@vapp) return @vapp,$status, $ip do
  @vapp.stop()
  $server_object = to_object(@vapp)
  $status = $server_object["details"][0]["status"]
  $ip = $server_object["details"][0]["ip"]
  call sys_log("server stopped",to_s($server))
end

# start the server from paused/suspended state
define do_start(@vapp) return @vapp,$status, $ip do
  @vapp.start()
  $server_object = to_object(@vapp)
  $status = $server_object["details"][0]["status"]
  $ip = $server_object["details"][0]["ip"]
  call sys_log("server start",to_s($server))
end

# power off the server from running state
define do_power_off(@vapp) return  @vapp,$status,$ip do
  @vapp.power_off()
  $server_object = to_object(@vapp)
  $status = $server_object["details"][0]["status"]
  $ip = $server_object["details"][0]["ip"]
  call sys_log("server powered off",to_s($server))
end

# power on the server from a stopped state
define do_power_on(@vapp) return @vapp,$status,$ip do
  @vapp.power_on()
  $server_object = to_object(@vapp)
  $status = $server_object["details"][0]["status"]
  $ip = $server_object["details"][0]["ip"]
  call sys_log("server powered on",to_s($server))
end

# make RS audit_entries
define sys_log($subject, $detail) do
  rs.audit_entries.create(
    notify: "None",
    audit_entry: {
      auditee_href: @@deployment,
      summary: $subject,
      detail: $detail
    }
  )
end

# get credentials from RS
define getCredential($cred) return $value do
  @cred = rs.credentials.get(filter: "name=="+$cred, view: "sensitive")
  $cred_object = to_object(@cred)
  $value = first($cred_object["details"])["value"]
end

# Returns the RightScale shard for the account the given CAT is launched in.
# It relies on the fact that when a CAT is launched, the resultant deployment description includes a link
# back to Self-Service.
# This link is exploited to identify the shard.
# Of course, this is somewhat dangerous because if the deployment description is changed to remove that link,
# this code will not work.
# Similarly, since the deployment description is also based on the CAT description, if the CAT author or publisher
# puts something like "selfservice-8" in it for some reason, this code will likely get confused.
# However, for the time being it's fine.
define find_shard(@deployment) return $shard_number do

  $deployment_description = @deployment.description
  #rs.audit_entries.create(notify: "None", audit_entry: { auditee_href: @deployment, summary: "deployment description" , detail: $deployment_description})

  # initialize a value
  $shard_number = "UNKNOWN"
  foreach $word in split($deployment_description, "/") do
    if $word =~ "selfservice-"
      foreach $character in split($word, "") do
        if $character =~ /[0-9]/
          $shard_number = $character
        end
      end
    end
  end
end
