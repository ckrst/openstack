#
# Cookbook Name:: openstack
# Recipe:: default
#
# Copyright (C) 2016 Vinícius kirst
#
# All rights reserved - Do Not Redistribute
#

package 'software-properties-common'

apt_repository 'cloud-archive:mitaka'

package 'python-openstackclient'

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


# TODO Keystone

mysql_database 'keystone' do
  connection mysql_connection_info
  action :create
end

mysql_database_user 'keystone' do
  connection mysql_connection_info
  password   'secret'
  action     :create
end
mysql_database_user 'keystone' do
  connection    mysql_connection_info
  password      'secret'
  database_name 'keystone'
  host          '%'
  privileges    [:all]
  action        :grant
end
mysql_database_user 'keystone' do
  connection    mysql_connection_info
  password      'secret'
  database_name 'keystone'
  host          'localhost'
  privileges    [:all]
  action        :grant
end

package 'keystone'

#APACHE
httpd_service 'default' do
    servername 'controller'
  action [:create, :start]
end

httpd_config 'wsgi-keystone' do
  source 'wsgi-keystone.erb'
  action :create
end

# By default, the Ubuntu packages create an SQLite database. Because this configuration uses an SQL database server, you can remove the SQLite database file:
file '/var/lib/keystone/keystone.db' do
    action :delete
end


# TODO Glance

mysql_database 'glance' do
  connection mysql_connection_info
  action :create
end

mysql_database_user 'glance' do
  connection mysql_connection_info
  password   'secret'
  action     :create
end
mysql_database_user 'glance' do
  connection    mysql_connection_info
  password      'secret'
  database_name 'glance'
  host          '%'
  privileges    [:all]
  action        :grant
end
mysql_database_user 'glance' do
  connection    mysql_connection_info
  password      'secret'
  database_name 'glance'
  host          'localhost'
  privileges    [:all]
  action        :grant
end

package 'glance'



# TODO Nova

mysql_database 'nova_api' do
  connection mysql_connection_info
  action :create
end

mysql_database 'nova' do
  connection mysql_connection_info
  action :create
end

mysql_database_user 'nova' do
  connection mysql_connection_info
  password   'secret'
  action     :create
end
mysql_database_user 'nova' do
  connection    mysql_connection_info
  password      'secret'
  database_name 'nova'
  host          '%'
  privileges    [:all]
  action        :grant
end
mysql_database_user 'nova' do
  connection    mysql_connection_info
  password      'secret'
  database_name 'nova'
  host          'localhost'
  privileges    [:all]
  action        :grant
end
mysql_database_user 'nova' do
  connection mysql_connection_info
  password   'secret'
  action     :create
end
mysql_database_user 'nova' do
  connection    mysql_connection_info
  password      'secret'
  database_name 'nova_api'
  host          '%'
  privileges    [:all]
  action        :grant
end
mysql_database_user 'nova' do
  connection    mysql_connection_info
  password      'secret'
  database_name 'nova_api'
  host          'localhost'
  privileges    [:all]
  action        :grant
end

package 'nova-api'
package 'nova-conductor'
package 'nova-consoleauth'
package 'nova-novncproxy'
package 'nova-scheduler'

# TODO Neutron

mysql_database 'neutron' do
  connection mysql_connection_info
  action :create
end

mysql_database_user 'neutron' do
  connection mysql_connection_info
  password   'secret'
  action     :create
end
mysql_database_user 'neutron' do
  connection    mysql_connection_info
  password      'secret'
  database_name 'neutron'
  host          '%'
  privileges    [:all]
  action        :grant
end
mysql_database_user 'neutron' do
  connection    mysql_connection_info
  password      'secret'
  database_name 'neutron'
  host          'localhost'
  privileges    [:all]
  action        :grant
end

package 'neutron-server'
package 'neutron-plugin-ml2'
package 'neutron-linuxbridge-agent'
package 'neutron-dhcp-agent'
package 'neutron-metadata-agent'
package 'neutron-l3-agent'

# TODO Dashboard
package 'openstack-dashboard'

# TODO Cinder

mysql_database 'cinder' do
  connection mysql_connection_info
  action :create
end

mysql_database_user 'cinder' do
  connection mysql_connection_info
  password   'secret'
  action     :create
end
mysql_database_user 'cinder' do
  connection    mysql_connection_info
  password      'secret'
  database_name 'cinder'
  host          '%'
  privileges    [:all]
  action        :grant
end
mysql_database_user 'cinder' do
  connection    mysql_connection_info
  password      'secret'
  database_name 'cinder'
  host          'localhost'
  privileges    [:all]
  action        :grant
end

package 'cinder-api'
package 'cinder-scheduler'
