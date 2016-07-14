tag 'neutron'

mysql_connection_info = {
    :host     => node['openstack']['db']['host'],
    :username => 'root',
    :password => node['openstack']['db']['root_password']
}

mysql_database node['openstack']['neutron']['db_name'] do
  connection mysql_connection_info
  action :create
end

mysql_database_user node['openstack']['neutron']['db_user'] do
  connection mysql_connection_info
  password   node['openstack']['neutron']['db_pass']
  action     :create
end
mysql_database_user node['openstack']['neutron']['db_user'] do
  connection    mysql_connection_info
  password      node['openstack']['neutron']['db_pass']
  database_name node['openstack']['neutron']['db_name']
  host          '%'
  privileges    [:all]
  action        :grant
end
mysql_database_user node['openstack']['neutron']['db_user'] do
  connection    mysql_connection_info
  password      node['openstack']['neutron']['db_pass']
  database_name node['openstack']['neutron']['db_name']
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

file '/etc/neutron/metadata_agent.ini' do
    content '
[DEFAULT]
nova_metadata_ip = controller
metadata_proxy_shared_secret = secret

[AGENT]
'
end

file '/etc/neutron/neutron.conf' do
    content "
[DEFAULT]

core_plugin = ml2
service_plugins = router
allow_overlapping_ips = True
rpc_backend = rabbit
auth_strategy = keystone
notify_nova_on_port_status_changes = True
notify_nova_on_port_data_changes = True

[agent]

root_helper = sudo /usr/bin/neutron-rootwrap /etc/neutron/rootwrap.conf

[cors]

[cors.subdomain]

[database]

connection = mysql+pymysql://#{node['openstack']['neutron']['db_user']}:#{node['openstack']['neutron']['db_pass']}@#{node['openstack']['db']['host']}/#{node['openstack']['neutron']['db_name']}

[keystone_authtoken]

auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = #{node['openstack']['neutron']['username']}
password = #{node['openstack']['neutron']['password']}

[matchmaker_redis]

[nova]

auth_url = http://controller:35357
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = #{node['openstack']['nova']['username']}
password = #{node['openstack']['nova']['password']}

[oslo_concurrency]

[oslo_messaging_amqp]

[oslo_messaging_notifications]

[oslo_messaging_rabbit]

rabbit_host = controller
rabbit_userid = openstack
rabbit_password = secret

[oslo_policy]

[quotas]

[ssl]
"
end

file '/etc/neutron/plugins/ml2/ml2_conf.ini' do
    content "
[DEFAULT]

[ml2]

type_drivers = flat,vlan,vxlan
tenant_network_types = vxlan
mechanism_drivers = linuxbridge,l2population
extension_drivers = port_security

[ml2_type_flat]

flat_networks = provider

[ml2_type_geneve]

[ml2_type_gre]

[ml2_type_vlan]

[ml2_type_vxlan]

vni_ranges = 1:1000

[securitygroup]

enable_ipset = True
"
end

file '/etc/neutron/plugins/ml2/linuxbridge_agent.ini' do
    content "
[DEFAULT]

[agent]

[linux_bridge]
physical_interface_mappings = provider:eth1

[securitygroup]
enable_security_group = True
firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

[vxlan]
enable_vxlan = True
local_ip = #{node['openstack']['nodes']['controller']['ipaddress']}
l2_population = True
"
end


file '/etc/neutron/l3_agent.ini' do
    content '
[DEFAULT]
interface_driver = neutron.agent.linux.interface.BridgeInterfaceDriver
external_network_bridge =

[AGENT]
'
end

file '/etc/neutron/dhcp_agent.ini' do
    content '
[DEFAULT]

interface_driver = neutron.agent.linux.interface.BridgeInterfaceDriver
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
enable_isolated_metadata = True

[AGENT]
'
end
