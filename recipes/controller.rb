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
    options '-y --force-yes'
end

# DB

mysql_service 'default' do
    port '3306'
    version '5.6'
    initial_root_password 'secret'
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
    :host     => '127.0.0.1',
    :username => 'root',
    :password => 'secret'
}

# RABBITMQ

rabbitmq_user "openstack" do
  password "secret"
  action :add
end
rabbitmq_user "openstack" do
  vhost "/"
  permissions ".* .* .*"
  action :set_permissions
end

file '/home/vagrant/admin-openrc' do
    content '
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=secret
export OS_AUTH_URL=http://controller:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
'
end

file '/home/vagrant/demo-openrc' do
    content '
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=demo
export OS_USERNAME=demo
export OS_PASSWORD=secret
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2'
end


# Nova
# include_recipe "openstack::nova"
#
# # Neutron
# include_recipe "openstack::neutron"
#
# # Dashboard
# include_recipe "openstack::horizon"
#
# # Cinder
# include_recipe "openstack::cinder"
