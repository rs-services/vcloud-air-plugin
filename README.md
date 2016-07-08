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

### Dependencies
* Ruby 2.2 or later
* [vcloud-rest](https://github.com/vmware/vcloud-rest)


### Configuration
* git clone git@github.com:rs-services/vcloud-air-plugin.git
* cd vcloud-air-plugin
* cp config/vcloudair.example config/vcloudair.yml
* change/add values in config/vcloudair.yml
* bundle install

### Running the server
* bundle exec rails s -d -e production -p 8080
* tail -f logs/production.log

### Example CloudApp
Use the example CloudApp [vcloudair-plugin.rb](vcloudair-plugin.rb) to create a single server in
the vCloudAir Environment.  You'll want to change the os_mapping values to match your template names.  
Also change the vapp resource attributes to match your vCloudAir Environment, such as vDC, or, catalog
etc.


### Testing
* bundle exec rspec
