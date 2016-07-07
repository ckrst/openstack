
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

file '/etc/glance/glance-api.conf' do
    content '[DEFAULT]

[cors]

[cors.subdomain]

[database]

connection = mysql+pymysql://glance:GLANCE_DBPASS@controller/glance

# sqlite_db = /var/lib/glance/glance.sqlite
# backend = sqlalchemy
connection = mysql+pymysql://glance:GLANCE_DBPASS@controller/glance

[glance_store]

stores = file,http
default_store = file
filesystem_store_datadir = /var/lib/glance/images/

[image_format]

disk_formats = ami,ari,aki,vhd,vmdk,raw,qcow2,vdi,iso,root-tar

[keystone_authtoken]

auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = glance
password = secret

[matchmaker_redis]

[oslo_concurrency]

[oslo_messaging_amqp]

[oslo_messaging_notifications]

[oslo_messaging_rabbit]

[oslo_policy]

[paste_deploy]

flavor = keystone

[profiler]

[store_type_location_strategy]

[task]

[taskflow_executor]

'
end

file '/etc/glance/glance-registry.conf' do
    content '
[DEFAULT]

[database]

# sqlite_db = /var/lib/glance/glance.sqlite
# backend = sqlalchemy
connection = mysql+pymysql://glance:secret@127.0.0.1/glance

[glance_store]

[keystone_authtoken]

auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = glance
password = secret

[matchmaker_redis]

[oslo_messaging_amqp]

[oslo_messaging_notifications]

[oslo_messaging_rabbit]

[oslo_policy]

[paste_deploy]

flavor = keystone

[profiler]
'
end
