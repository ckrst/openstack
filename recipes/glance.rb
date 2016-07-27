tag 'glance'

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

template "/etc/glance/glance-api.conf" do
    source 'glance-api.conf.erb'
    mode '0644'
    owner 'root'
    group 'root'
end

template "/etc/glance/glance-registry.conf" do
    source 'glance-api.conf.erb'
    mode '0644'
    owner 'root'
    group 'root'
end


# Add the admin role to the glance user and service project: (to be executed after glance_user)
execute 'bind_glance_role' do
    command "openstack role add --project service --user #{node['openstack']['glance']['username']} admin"
    environment admin_env
    action :nothing
end

# create the service credentials
# Create the glance user:
execute 'glance_user' do
    command "openstack user create --domain default --password \"#{node['openstack']['glance']['password']}\" #{node['openstack']['glance']['username']}"
    environment admin_env
    not_if "openstack user show #{node['openstack']['glance']['username']}"
    notifies :run, "execute[bind_glance_role]", :immediately
end


# Create the glance service entity:
execute 'glance_service_entity' do
    command "openstack service create --name glance --description \"OpenStack Image\" image"
    environment admin_env
    not_if "openstack service show glance"
end

# Create the Image service API endpoints:
execute 'glance_endpoint_public' do
    command "openstack endpoint create --region RegionOne image public http://#{node['openstack']['nodes']['controller']['hostname']}:9292"
    environment admin_env
    not_if "openstack endpoint list --service glance --interface public | grep public"
end
execute 'glance_endpoint_internal' do
    command "openstack endpoint create --region RegionOne image internal http://#{node['openstack']['nodes']['controller']['hostname']}:9292"
    environment admin_env
    not_if "openstack endpoint list --service glance --interface internal | grep internal"
end
execute 'glance_endpoint_admin' do
    command "openstack endpoint create --region RegionOne image admin http://#{node['openstack']['nodes']['controller']['hostname']}:9292"
    environment admin_env
    not_if "openstack endpoint list --service glance --interface admin | grep admin"
end

service 'glance-registry'
service 'glance-api'

# Populate the Image service database:
execute 'populate_glance' do
    command "su -s /bin/sh -c \"glance-manage db_sync\" #{node['openstack']['glance']['db_name']}  && touch /root/.osc/glance_db_ok"
    not_if { File.exists?("/root/.osc/glance_db_ok") }
    notifies :restart, 'service[glance-registry]', :immediately
    notifies :restart, 'service[glance-api]', :immediately
end


# Import ubuntu
directory '/glance_images'
remote_file '/glance_images/trusty-server-cloudimg-amd64-disk1.img' do
  source 'https://cloud-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-disk1.img'
  mode '0755'
  action :create
end
execute 'import_ubuntu' do
    command "openstack image create \"ubuntu\" --file /glance_images/trusty-server-cloudimg-amd64-disk1.img --disk-format qcow2 --container-format bare --public"
    environment admin_env
    not_if "openstack image show ubuntu"
end
execute 'glance_image_list' do
    command "openstack image list"
    environment admin_env
end
