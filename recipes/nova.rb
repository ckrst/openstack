tag 'nova'

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

mysql_database node['openstack']['nova']['db_name'] do
  connection mysql_connection_info
  action :create
end
mysql_database node['openstack']['nova_api']['db_name'] do
    connection mysql_connection_info
    action :create
end

mysql_database_user node['openstack']['nova']['db_user'] do
  connection mysql_connection_info
  password   node['openstack']['nova']['db_pass']
  action     :create
end
mysql_database_user node['openstack']['nova']['db_user'] do
  connection    mysql_connection_info
  password      node['openstack']['nova']['db_pass']
  database_name node['openstack']['nova']['db_name']
  host          '%'
  privileges    [:all]
  action        :grant
end
mysql_database_user node['openstack']['nova']['db_user'] do
  connection    mysql_connection_info
  password      node['openstack']['nova']['db_pass']
  database_name node['openstack']['nova']['db_name']
  host          'localhost'
  privileges    [:all]
  action        :grant
end
mysql_database_user node['openstack']['nova']['db_user'] do
  connection    mysql_connection_info
  password      node['openstack']['nova']['db_pass']
  database_name node['openstack']['nova_api']['db_name']
  host          '%'
  privileges    [:all]
  action        :grant
end
mysql_database_user node['openstack']['nova']['db_user'] do
  connection    mysql_connection_info
  password      node['openstack']['nova']['db_pass']
  database_name node['openstack']['nova_api']['db_name']
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

service 'nova-api'
service 'nova-consoleauth'
service 'nova-scheduler'
service 'nova-conductor'
service 'nova-novncproxy'

template "/etc/nova/nova.conf" do
    source 'nova.conf.controller.erb'
    mode '0644'
    owner 'root'
    group 'root'
end

# Add the admin role to the nova user: (to be executed after nova_user)
execute 'bind_nova_user' do
    command "openstack role add --project service --user #{node['openstack']['nova']['username']} admin"
    environment admin_env
    action :nothing
end

# create the service credentials
# Create the nova user:
execute 'nova_user' do
    command "openstack user create --domain default --password \"#{node['openstack']['nova']['password']}\" #{node['openstack']['nova']['username']}"
    environment admin_env
    not_if "openstack user show #{node['openstack']['nova']['username']}"
    notifies :run, "execute[bind_nova_user]", :immediately
end


# Create the nova service entity:
execute 'nova_service_entity' do
    command "openstack service create --name nova --description \"OpenStack Compute\" compute"
    environment admin_env
    not_if "openstack service show compute"
end

# Create the Compute service API endpoints:
execute 'nova_endpoint_public' do
    command "openstack endpoint create --region RegionOne compute public http://#{node['openstack']['nodes']['controller']['hostname']}:8774/v2.1/%\\(tenant_id\\)s"
    environment admin_env
    not_if "openstack endpoint list --service compute --interface public | grep public"
end
execute 'nova_endpoint_internal' do
    command "openstack endpoint create --region RegionOne compute internal http://#{node['openstack']['nodes']['controller']['hostname']}:8774/v2.1/%\\(tenant_id\\)s"
    environment admin_env
    not_if "openstack endpoint list --service compute --interface internal | grep internal"
end
execute 'nova_endpoint_admin' do
    command "openstack endpoint create --region RegionOne compute admin http://#{node['openstack']['nodes']['controller']['hostname']}:8774/v2.1/%\\(tenant_id\\)s"
    environment admin_env
    not_if "openstack endpoint list --service compute --interface admin | grep admin"
end

# Populate the Compute databases:
execute 'populate_nova_api_db' do
    command "su -s /bin/sh -c \"nova-manage api_db sync\" nova  && touch /root/.osc/nova_api_db_ok"
    environment admin_env
    not_if { File.exists?("/root/.osc/nova_api_db_ok") }
end
execute 'populate_nova_db' do
    command "su -s /bin/sh -c \"nova-manage db sync\" nova && touch /root/.osc/nova_db_ok"
    environment admin_env
    not_if { File.exists?("/root/.osc/nova_db_ok") }
    notifies :restart, 'service[nova-api]', :immediately
    notifies :restart, 'service[nova-consoleauth]', :immediately
    notifies :restart, 'service[nova-scheduler]', :immediately
    notifies :restart, 'service[nova-conductor]', :immediately
    notifies :restart, 'service[nova-novncproxy]', :immediately
end
