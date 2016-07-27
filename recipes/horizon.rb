
tag 'horizon'

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

package 'openstack-dashboard' do
    options '-y --force-yes'
end

mysql_connection_info = {
    :host     => node['openstack']['db']['host'],
    :username => 'root',
    :password => node['openstack']['db']['root_password']
}

mysql_database node['openstack']['horizon']['db_name'] do
  connection mysql_connection_info
  action :create
end
mysql_database_user node['openstack']['horizon']['db_user'] do
  connection mysql_connection_info
  password   node['openstack']['horizon']['db_pass']
  action     :create
end
mysql_database_user node['openstack']['horizon']['db_user'] do
  connection    mysql_connection_info
  password      node['openstack']['horizon']['db_pass']
  database_name node['openstack']['horizon']['db_name']
  host          '%'
  privileges    [:all]
  action        :grant
end
mysql_database_user node['openstack']['horizon']['db_user'] do
  connection    mysql_connection_info
  password      node['openstack']['horizon']['db_pass']
  database_name node['openstack']['horizon']['db_name']
  host          'localhost'
  privileges    [:all]
  action        :grant
end

# service 'nova-api'
# service 'apache2'

template "/etc/openstack-dashboard/local_settings.py" do
    source 'local_settings.py.erb'
    mode '0644'
    owner 'root'
    group 'root'
end

directory '/var/lib/dash/.blackhole' do
    recursive true
end

execute 'populate_horizon_db' do
    command "/usr/share/openstack-dashboard/manage.py syncdb --noinput && touch /root/.osc/horizon_db_ok"
    environment admin_env
    not_if { File.exists?("/root/.osc/horizon_db_ok") }
    notifies :restart, 'service[nova-api]', :immediately
    notifies :restart, 'service[apache2]', :immediately
end
