tag 'neutron'

admin_env = {
    "OS_PROJECT_DOMAIN_NAME" => "default",
    "OS_USER_DOMAIN_NAME" => "default",
    "OS_PROJECT_NAME" => "admin",
    "OS_USERNAME" => node['openstack']['admin_user'],
    "OS_PASSWORD" => node['openstack']['admin_password'],
    "OS_AUTH_URL" => "http://#{node['openstack']['nodes']['controller']['hostname']}:35357/v3",
    "OS_IDENTITY_API_VERSION" => "3",
    "OS_IMAGE_API_VERSION" => "2"
}

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

service 'nova-api'
service 'neutron-server'
service 'neutron-linuxbridge-agent'
service 'neutron-dhcp-agent'
service 'neutron-metadata-agent'
service 'neutron-l3-agent'

template "/etc/neutron/metadata_agent.ini" do
    source 'metadata_agent.ini.erb'
    mode '0644'
    owner 'root'
    group 'root'
end

template "/etc/neutron/neutron.conf" do
    source 'neutron.conf.controller.erb'
    mode '0644'
    owner 'root'
    group 'root'
end

template "/etc/neutron/plugins/ml2/ml2_conf.ini" do
    source 'ml2_conf.ini.erb'
    mode '0644'
    owner 'root'
    group 'root'
end

template "/etc/neutron/plugins/ml2/linuxbridge_agent.ini" do
    source 'linuxbridge_agent.ini.erb'
    mode '0644'
    owner 'root'
    group 'root'
end

template "/etc/neutron/l3_agent.ini" do
    source 'l3_agent.ini.erb'
    mode '0644'
    owner 'root'
    group 'root'
end

template "/etc/neutron/dhcp_agent.ini" do
    source 'dhcp_agent.ini.erb'
    mode '0644'
    owner 'root'
    group 'root'
end


# create the service credentials
# Add the admin role to the neutron user: (to be executed after neutron_service_credentials)
execute 'bind_neutron_role' do
    command "openstack role add --project service --user #{node['openstack']['neutron']['username']} admin"
    environment admin_env
    action :nothing
end
# Create the neutron user:
execute 'neutron_service_credentials' do
    command "openstack user create --domain default --password \"#{node['openstack']['neutron']['password']}\" #{node['openstack']['neutron']['username']}"
    environment admin_env
    not_if "openstack user show #{node['openstack']['neutron']['username']}"
    notifies :run, "execute[bind_neutron_role]", :immediately
end

# Create the neutron service entity:
execute 'neutron_service_entity' do
    command "openstack service create --name neutron --description \"OpenStack Networking\" network"
    environment admin_env
    not_if "openstack service show network"
end

# Create the Networking service API endpoints:
execute 'neutron_endpoint_public' do
    command "openstack endpoint create --region RegionOne network public http://#{node['openstack']['nodes']['controller']['hostname']}:9696"
    environment admin_env
    not_if "openstack endpoint list --service network --interface public | grep public"
end
execute 'neutron_endpoint_internal' do
    command "openstack endpoint create --region RegionOne network internal http://#{node['openstack']['nodes']['controller']['hostname']}:9696"
    environment admin_env
    not_if "openstack endpoint list --service network --interface internal | grep internal"
end
execute 'neutron_endpoint_admin' do
    command "openstack endpoint create --region RegionOne network admin http://#{node['openstack']['nodes']['controller']['hostname']}:9696"
    environment admin_env
    not_if "openstack endpoint list --service network --interface admin | grep admin"
end

# Populate the database:
execute 'populate_neutron_db' do
    command "su -s /bin/sh -c \"neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head\" neutron && touch /root/.osc/neutron_db_ok"
    environment admin_env
    not_if { File.exists?("/root/.osc/neutron_db_ok") }
    notifies :restart, 'service[nova-api]', :immediately
    notifies :restart, 'service[neutron-server]', :immediately
    notifies :restart, 'service[neutron-linuxbridge-agent]', :immediately
    notifies :restart, 'service[neutron-dhcp-agent]', :immediately
    notifies :restart, 'service[neutron-metadata-agent]', :immediately
    notifies :restart, 'service[neutron-l3-agent]', :immediately
end
