mysql_connection_info = {
    :host     => '127.0.0.1',
    :username => 'root',
    :password => 'secret'
}
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
