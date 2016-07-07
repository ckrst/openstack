

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

file '/etc/nova/nova.conf' do
    content '
[DEFAULT]
dhcpbridge_flagfile=/etc/nova/nova.conf
dhcpbridge=/usr/bin/nova-dhcpbridge
logdir=/var/log/nova
state_path=/var/lib/nova
lock_path=/var/lock/nova
force_dhcp_release=True
libvirt_use_virtio_for_bridges=True
verbose=True
ec2_private_dns_show_ip=True
api_paste_config=/etc/nova/api-paste.ini
# enabled_apis=ec2,osapi_compute,metadata
enabled_apis=osapi_compute,metadata
rpc_backend=rabbit
auth_strategy = keystone
my_ip=10.0.0.11
use_neutron=True
firewall_driver=nova.virt.firewall.NoopFirewallDriver

[api_database]
connection = mysql+pymysql://nova:secret@127.0.0.1/nova_api

[database]
connection = mysql+pymysql://nova:secret@127.0.0.1/nova

[oslo_messaging_rabbit]
rabbit_host=controller
rabbit_userid=openstack
rabbit_password=secret

[oslo_concurrency]
lock_path = /var/lib/nova/tmp

[keystone_authtoken]
auth_uri=http://controller:5000
auth_url=http://controller:35357
memcached_servers=controller:11211
auth_type=password
project_domain_name=default
user_domain_name=default
project_name=service
username=nova
password=secret

[vnc]
vncserver_listen = $my_ip
vncserver_proxyclient_address = $my_ip

[glance]
api_servers = http://controller:9292

[neutron]
url = http://controller:9696
auth_url = http://controller:35357
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = secret

service_metadata_proxy = True
metadata_proxy_shared_secret = secret
'
end
