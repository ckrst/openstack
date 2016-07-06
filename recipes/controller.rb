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
    options '-y --force-yes'
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

file '/etc/init/keystone.override' do
    content 'manual'
end

package 'keystone' do
    options '--force-yes'
end

file '/etc/keystone/keystone.conf' do
    content '
[DEFAULT]

admin_token = 71e444e5726be697906c

log_dir = /var/log/keystone

[assignment]

[auth]

[cache]

[catalog]

[cors]

[cors.subdomain]

[credential]

[database]

connection = mysql+pymysql://keystone:secret@127.0.0.1/keystone

[domain_config]

[endpoint_filter]

[endpoint_policy]

[eventlet_server]

[eventlet_server_ssl]

[federation]

[fernet_tokens]

[identity]

[identity_mapping]

[kvs]

[ldap]

[matchmaker_redis]

[memcache]

[oauth1]

[os_inherit]

[oslo_messaging_amqp]

[oslo_messaging_notifications]

[oslo_messaging_rabbit]

[oslo_middleware]

[oslo_policy]

[paste_deploy]

[policy]

[resource]

[revoke]

[role]

[saml]

[shadow_users]

[signing]

[ssl]

[token]

provider = fernet

[tokenless_auth]

[trust]

[extra_headers]
Distribution = Ubuntu
'
end

#APACHE
# httpd_service 'default' do
#     servername 'controller'
#   action [:create, :start]
# end
#
# httpd_config 'wsgi-keystone' do
#   source 'wsgi-keystone.erb'
#   action :create
# end

#include_recipe "apache2"

package 'apache2' do
    options '--force-yes'
    action :install
end
package 'libapache2-mod-wsgi' do
    options '--force-yes'
    action :install
end

# web_app "wsgi-keystone" do
#   template 'wsgi-keystone.erb'
#   server_name 'controller'
# end

file '/etc/apache2/sites-available/wsgi-keystone.conf' do
    content '
Listen 5000
Listen 35357

<VirtualHost *:5000>
    WSGIDaemonProcess keystone-public processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-public
    WSGIScriptAlias / /usr/bin/keystone-wsgi-public
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    ErrorLogFormat "%{cu}t %M"
    ErrorLog /var/log/apache2/keystone.log
    CustomLog /var/log/apache2/keystone_access.log combined

    <Directory /usr/bin>
        Require all granted
    </Directory>
</VirtualHost>

<VirtualHost *:35357>
    WSGIDaemonProcess keystone-admin processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-admin
    WSGIScriptAlias / /usr/bin/keystone-wsgi-admin
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    ErrorLogFormat "%{cu}t %M"
    ErrorLog /var/log/apache2/keystone.log
    CustomLog /var/log/apache2/keystone_access.log combined

    <Directory /usr/bin>
        Require all granted
    </Directory>
</VirtualHost>'
end

link '/etc/apache2/sites-enabled/wsgi-keystone.conf' do
  to '/etc/apache2/sites-available/wsgi-keystone.conf'
  link_type :symbolic
end

service "apache2" do
  action [:restart]
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

package 'glance' do
    options '-y --force-yes'
end



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

package 'nova-api' do
    options '-y --force-yes'
end
package 'nova-conductor' do
    options '-y --force-yes'
end
package 'nova-consoleauth' do
    options '-y --force-yes'
end
package 'nova-novncproxy' do
    options '-y --force-yes'
end
package 'nova-scheduler' do
    options '-y --force-yes'
end

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

package 'neutron-server' do
    options '-y --force-yes'
end
package 'neutron-plugin-ml2' do
    options '-y --force-yes'
end
package 'neutron-linuxbridge-agent' do
    options '-y --force-yes'
end
package 'neutron-dhcp-agent' do
    options '-y --force-yes'
end
package 'neutron-metadata-agent' do
    options '-y --force-yes'
end
package 'neutron-l3-agent' do
    options '-y --force-yes'
end

# TODO Dashboard
package 'openstack-dashboard' do
    options '-y --force-yes'
end

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

package 'cinder-api' do
    options '-y --force-yes'
end
package 'cinder-scheduler' do
    options '-y --force-yes'
end
