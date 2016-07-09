tag 'glance'

mysql_connection_info = {
    :host     => node['openstack']['db']['host'],
    :username => 'root',
    :password => node['openstack']['db']['root_password']
}

mysql_database node['openstack']['glance']['db_name'] do
  connection mysql_connection_info
  action :create
end

mysql_database_user node['openstack']['glance']['db_user'] do
  connection mysql_connection_info
  password   node['openstack']['glance']['db_pass']
  action     :create
end
mysql_database_user node['openstack']['glance']['db_user'] do
  connection    mysql_connection_info
  password      node['openstack']['glance']['db_pass']
  database_name node['openstack']['glance']['db_name']
  host          '%'
  privileges    [:all]
  action        :grant
end
mysql_database_user node['openstack']['glance']['db_user'] do
  connection    mysql_connection_info
  password      node['openstack']['glance']['db_pass']
  database_name node['openstack']['glance']['db_name']
  host          'localhost'
  privileges    [:all]
  action        :grant
end

package 'glance' do
    options '-y --force-yes'
end

file '/etc/glance/glance-api.conf' do
    content "[DEFAULT]

[cors]

[cors.subdomain]

[database]

# sqlite_db = /var/lib/glance/glance.sqlite
# backend = sqlalchemy
connection = mysql+pymysql://#{node['openstack']['glance']['db_user']}:#{node['openstack']['glance']['db_pass']}@#{node['openstack']['db']['host']}/#{node['openstack']['glance']['db_name']}

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
username = #{node['openstack']['glance']['username']}
password = #{node['openstack']['glance']['password']}

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

"
end

file '/etc/glance/glance-registry.conf' do
    content "
[DEFAULT]

[database]

# sqlite_db = /var/lib/glance/glance.sqlite
# backend = sqlalchemy
connection = mysql+pymysql://#{node['openstack']['glance']['db_user']}:#{node['openstack']['glance']['db_pass']}@#{node['openstack']['db']['host']}/#{node['openstack']['glance']['db_name']}

[glance_store]

[keystone_authtoken]

auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = #{node['openstack']['glance']['username']}
password = #{node['openstack']['glance']['password']}

[matchmaker_redis]

[oslo_messaging_amqp]

[oslo_messaging_notifications]

[oslo_messaging_rabbit]

[oslo_policy]

[paste_deploy]

flavor = keystone

[profiler]
"
end
