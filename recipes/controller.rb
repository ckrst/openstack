#
# Cookbook Name:: openstack
# Recipe:: default
#
# Copyright (C) 2016 Vinícius kirst
#
# All rights reserved - Do Not Redistribute
#

hostsfile_entry '10.0.0.31' do
    hostname 'compute1'
    action :create_if_missing
end

hostsfile_entry '10.0.0.41' do
    hostname 'block1'
    action :create_if_missing
end

package 'software-properties-common' do
    options '--force-yes'
end

apt_repository 'cloudarchive-mitaka' do
    uri 'http://ubuntu-cloud.archive.canonical.com/ubuntu'
    distribution 'trusty-updates/mitaka'
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

# RABBITMQ

rabbitmq_user node['openstack']['rabbitmq']['user'] do
  password node['openstack']['rabbitmq']['password']
  action :add
end
rabbitmq_user node['openstack']['rabbitmq']['user'] do
  vhost "/"
  permissions ".* .* .*"
  action :set_permissions
end



file '/home/vagrant/admin-openrc' do
    content "
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=secret
export OS_AUTH_URL=http://controller:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
"
end

file '/home/vagrant/demo-openrc' do
    content "
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=demo
export OS_USERNAME=demo
export OS_PASSWORD=secret
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
"
end


package 'memcached'

file '/etc/memcached.conf' do
    content'
-d

logfile /var/log/memcached.log

-m 64

-p 11211

-u memcache

-l 10.0.0.11
'
end

service 'memcached' do
    action [ :restart ]
end
