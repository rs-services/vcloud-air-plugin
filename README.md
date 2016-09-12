# vCloud Air Plugin

This is a RightScale Self-Service plugin for vCloud Air.  The Plugin will allow
launching, stop, start, and destroy a vapp/vm in vCloud Air.

The plugin is built as a Ruby on Rails API only app.  It must be reachable by the
Self-Server servers.  Configure the CloudApp namespace service host variable to the
hostname and port where this service is hosted.  

### Requirements
* [RightLink UCA](http://uca.surge.sh/)
* [RightLink 10](http://docs.rightscale.com/rl10/)
* vCloud Air networks must must route to the internet to allow enable RightLink 10
* vCloud Air Dedicated account
* CentOS, Ubuntu or Windows 2012 Templates
* 

### Limitations/Known Issues
* Cloud app and server names must be unique.  vCloud Air dosen't allow duplicate vm/vapp names
* Launching a server in vcloud air occationally fails.  vCloud air API tasks respond with completed but subsequent on the vm fails.
*

### Dependencies
* Ruby 2.2 or later
* [vcloud-rest](https://github.com/vmware/vcloud-rest)


### Configuration
* git clone git@github.com:rs-services/vcloud-air-plugin.git
* cd vcloud-air-plugin
* cp config/vcloudair.example config/vcloudair.yml
* change/add values in config/vcloudair.yml
   * Add vCloud Air API Host - API endpoint
   * Add vCloud Air API username
   * Add vCloud Air API Password
   * Add vCloud Air API Organization
   * Add API-Shared-Secret to match CAT file headers.
* bundle install

### Running the server
* bundle exec rails s -d -e production -p 8080
* tail -f logs/production.log

### Networking
There are a number of options for a network configuration. The only requirement is application must be accessible from the internet, through direct access or a tunnel in a private network, and must be able to reach the vCloud API Endpoint.  Common solutions would be to deploy in a public cloud with multiple VM's and a Load Balancer.  In a private network, using [ngrok](https://ngrok.com/) tunnel is roubust and secure. 

### Example CloudApp
Use the example CloudApp [vcloudair-plugin-cat.rb](vcloudair-plugin-cat.rb) to create a single server in
the vCloudAir Environment.  You'll want to change the os_mapping values to match your template names.  
Also change the vapp resource attributes to match your vCloudAir Environment, such as vDC, or, catalog
etc.


### Testing
* bundle exec rspec
