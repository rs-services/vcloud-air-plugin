name "vclould air plugin"
rs_ca_ver 20131202
short_description "vcloud-air plugin"

parameter "network" do
  type "list"
  label "Network"
  description "Select the network to launch into"
  allowed_values "TELSTRATESTVDC001-DEFAULT-ROUTED", "DAVETEST-NET","OnRampMigrations","TELSTRATESTVDC001-DEFAULT-ISOLATED"
  operations "launch"
end

parameter "os" do
  type "list"
  label "Operating System"
  description "Select the OS to boot"
  allowed_values "CentOS64-64BIT", "something else"
  operations "launch"
end

resource "vapp", type: "vcloudair.server" do
  org "TelstraTestvdc001"                   # the vcloudair organization
  name "curt-test-3"                        # the vapp name
  vdc "TelstraTestvdc001"                   # the virtual data center  for the vapp
  network $network                          # the network to place the vApp
  template $os                              # the template to build the vApp
  catalog "Public Catalog"                  # The catalog where to find the template
  description "My vApp from SelfService"    # The description of the vApp
end

namespace "vcloudair" do
  service do
    host "http://1d19b734.ngrok.io" # HTTP endpoint presenting an API defined by self-serviceto act on resources
    path "/plugin"  # path prefix for all resources, RightScale account_id substituted in for multi-tenancy
    headers do {
      "user-agent" => "self_service" ,     # special headers as needed
      "X-Api-Version" => "1.0",
      "X-Api-Shared-Secret" => "Change to a shared secret value"
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
    end
  end
end

# create new server, and return it's resoruce
define provision_vapp(@raw_server) return @vapp do
  @vapp = vcloudair.server.create({
    server:{
    org: @raw_server.org,
    name: @raw_server.name,
    vdc: @raw_server.vdc,
    network: @raw_server.network,
    template: @raw_server.template,
    catalog: @raw_server.catalog,
    description: @raw_server.description
  }
   })
   $server_object = to_object(@vapp)
   call sys_log("server created",to_s($server))
end
# delete the server and return the resoruce
define delete_vapp(@vapp) return @vapp do
  @server.destroy()
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
define launch_handler(@vapp) return @vapp, $status, $ip do

  provision(@vapp)

  $vapp_object = to_object(@vapp)
  $status = $vapp_object["details"][0]["status"]
  $ip = $vapp_object["details"][0]["ip"]
  call sys_log("server launched",to_s($server))
end

define do_stop(@vapp) return @vapp,$status, $ip do
  @vapp.stop()
  $server_object = to_object(@vapp)
  $status = $server_object["details"][0]["status"]
  $ip = $server_object["details"][0]["ip"]
  call sys_log("server stopped",to_s($server))
end

define do_start(@vapp) return @vapp,$status, $ip do
  @vapp.start()
  $server_object = to_object(@vapp)
  $status = $server_object["details"][0]["status"]
  $ip = $server_object["details"][0]["ip"]
  call sys_log("server start",to_s($server))
end

define do_power_off(@vapp) return  @vapp,$status,$ip do
  @vapp.power_off()
  $server_object = to_object(@vapp)
  $status = $server_object["details"][0]["status"]
  $ip = $server_object["details"][0]["ip"]
  call sys_log("server powered off",to_s($server))
end

define do_power_on(@vapp) return @vapp,$status,$ip do
  @vapp.power_on()
  $server_object = to_object(@vapp)
  $status = $server_object["details"][0]["status"]
  $ip = $server_object["details"][0]["ip"]
  call sys_log("server powered on",to_s($server))
end

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
