#
# Cookbook Name:: openstack
# Recipe:: default
#
# Copyright (C) 2016 Vinícius kirst
#
# All rights reserved - Do Not Redistribute
#

tag 'controllerNode'

include_recipe "chrony"


hostsfile_entry '127.0.1.1' do
    action :remove
end

hostsfile_entry node['openstack']['nodes']['controller']['ipaddress'] do
    hostname node['openstack']['nodes']['controller']['hostname']
    action :create_if_missing
end

# hostsfile_entry '10.0.0.31' do
#     hostname 'compute1'
#     action :create_if_missing
# end
#
# hostsfile_entry '10.0.0.41' do
#     hostname 'block1'
#     action :create_if_missing
# end
#

package 'software-properties-common' do
    options '--force-yes'
end

apt_repository "cloudarchive-#{node['openstack']['release']}" do
    uri 'http://ubuntu-cloud.archive.canonical.com/ubuntu'
    distribution "trusty-updates/#{node['openstack']['release']}"
    components ['main']
    action [:add]
end

package 'python-openstackclient' do
    options '--force-yes'
end

# DB

mysql_service 'default' do
    port '3306'
    version '5.6'
    initial_root_password node['openstack']['db']['root_password']
    action [:create, :start]
end

mysql_config 'openstack_defaults' do
    source 'my_extra_settings.erb'
    notifies :restart, 'mysql_service[default]'
    action :create
end

mysql2_chef_gem 'default' do
    action :install
end

mysql_connection_info = {
    :host     => node['openstack']['db']['host'],
    :username => 'root',
    :password => node['openstack']['db']['root_password']
}

package 'python-pymysql' do
    options '--force-yes'
end

# MongoDB
include_recipe "mongodb"

# RABBITMQ
include_recipe "rabbitmq"
rabbitmq_user node['openstack']['rabbitmq']['user'] do
  password node['openstack']['rabbitmq']['password']
  action :add
end
rabbitmq_user node['openstack']['rabbitmq']['user'] do
  vhost "/"
  permissions ".* .* .*"
  action :set_permissions
end



file '/root/admin-openrc' do
    content "
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=#{node['openstack']['admin_user']}
export OS_PASSWORD=#{node['openstack']['admin_password']}
export OS_AUTH_URL=http://#{node['openstack']['nodes']['controller']['hostname']}:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
"
end

file '/root/demo-openrc' do
    content "
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=demo
export OS_USERNAME=demo
export OS_PASSWORD=secret
export OS_AUTH_URL=http://#{node['openstack']['nodes']['controller']['hostname']}:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
"
end


package 'memcached'

file '/etc/memcached.conf' do
    content "
-d
logfile /var/log/memcached.log
-m 64
-p 11211
-u memcache
-l #{node['openstack']['nodes']['controller']['ipaddress']}
"
end
