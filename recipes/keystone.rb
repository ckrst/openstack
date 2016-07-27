tag 'keystone'

mysql_connection_info = {
    :host     => node['openstack']['db']['host'],
    :username => 'root',
    :password => node['openstack']['db']['root_password']
}

mysql_database node['openstack']['keystone']['db_name'] do
  connection mysql_connection_info
  action :create
end

mysql_database_user node['openstack']['keystone']['db_user'] do
  connection mysql_connection_info
  password   node['openstack']['keystone']['db_pass']
  action     :create
end
mysql_database_user node['openstack']['keystone']['db_user'] do
  connection    mysql_connection_info
  password      node['openstack']['keystone']['db_pass']
  database_name node['openstack']['keystone']['db_name']
  host          '%'
  privileges    [:all]
  action        :grant
end
mysql_database_user node['openstack']['keystone']['db_user'] do
  connection    mysql_connection_info
  password      node['openstack']['keystone']['db_pass']
  database_name node['openstack']['keystone']['db_name']
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
    content "
[DEFAULT]

admin_token = #{node['openstack']['admin_token']}

log_dir = /var/log/keystone

[assignment]

[auth]

[cache]

[catalog]

[cors]

[cors.subdomain]

[credential]

[database]

connection = mysql+pymysql://#{node['openstack']['keystone']['db_user']}:#{node['openstack']['keystone']['db_pass']}@#{node['openstack']['db']['host']}/#{node['openstack']['keystone']['db_name']}

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
"
end

# Populate the Identity service database
execute 'populate_keystone' do
    command "su -s /bin/sh -c \"keystone-manage db_sync\" #{node['openstack']['keystone']['db_name']}"
    action :nothing
end

#APACHE
package 'apache2' do
    options '--force-yes'
    action :install
end
package 'libapache2-mod-wsgi' do
    options '--force-yes'
    action :install
end

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

# By default, the Ubuntu packages create an SQLite database. Because this configuration uses an SQL database server, you can remove the SQLite database file:
file '/var/lib/keystone/keystone.db' do
    action :delete
end
