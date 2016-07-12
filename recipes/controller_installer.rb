




keystone_test_env = {
    "OS_TOKEN"                  => node['openstack']['admin_token'],
    "OS_URL"                    => "http://controller:35357/v3",
    "OS_IDENTITY_API_VERSION"   => "3"
}

admin_env = {
    "OS_PROJECT_DOMAIN_NAME" => "default",
    "OS_USER_DOMAIN_NAME" => "default",
    "OS_PROJECT_NAME" => "admin",
    "OS_USERNAME" => node['openstack']['admin_user'],
    "OS_PASSWORD" => node['openstack']['admin_password'],
    "OS_AUTH_URL" => "http://controller:35357/v3",
    "OS_IDENTITY_API_VERSION" => "3",
    "OS_IMAGE_API_VERSION" => "2"
}

user_env = {
    "OS_PROJECT_DOMAIN_NAME" => "default",
    "OS_USER_DOMAIN_NAME" => "default",
    "OS_PROJECT_NAME" => "demo",
    "OS_USERNAME" => "demo",
    "OS_PASSWORD" => "secret",
    "OS_AUTH_URL" => "http://controller:5000/v3",
    "OS_IDENTITY_API_VERSION" => "3",
    "OS_IMAGE_API_VERSION" => "2"
}


include_recipe "openstack::controller"

service 'mongodb' do
    action [ :restart ]
end

service 'memcached' do
    action [ :restart ]
end

###########################
# KEYSTONE
###########################

# Keystone
include_recipe "openstack::keystone"

# Populate the Identity service database
execute 'populate_keystone' do
    command "su -s /bin/sh -c \"keystone-manage db_sync\" #{node['openstack']['keystone']['db_name']}"
end

# Initialize Fernet keys
execute 'initialize_fernet_keys' do
    command "keystone-manage fernet_setup --keystone-user #{node['openstack']['keystone']['username']} --keystone-group #{node['openstack']['keystone']['username']}"
end

# Restart the Apache HTTP server
service 'apache2' do
    action [ :restart ]
end

# Create the service entity and API endpoints

# Create the service entity for the Identity service
execute 'create_keystone_entity' do
    command "openstack service create --name keystone --description \"OpenStack Identity\" identity"
    environment keystone_test_env
end

# Create the Identity service API endpoints
execute 'create_keystone_public_endpoint' do
    command 'openstack endpoint create --region RegionOne identity public http://controller:5000/v3'
    environment keystone_test_env
end
execute 'create_keystone_internal_endpoint' do
    command 'openstack endpoint create --region RegionOne identity internal http://controller:5000/v3'
    environment keystone_test_env
end
execute 'create_keystone_admin_endpoint' do
    command 'openstack endpoint create --region RegionOne identity admin http://controller:35357/v3'
    environment keystone_test_env
end

# Create a domain, projects, users, and roles

# Create the default domain
execute 'create_default_domain' do
    command 'openstack domain create --description "Default Domain" default'
    environment keystone_test_env
end


# Create an administrative project, user, and role for administrative operations in your environment
# Create the admin project:
execute 'create_admin_project' do
    command 'openstack project create --domain default --description "Admin Project" admin'
    environment keystone_test_env
end
# Create the admin user:
execute 'create_admin_user' do
    command "openstack user create --domain default --password \"#{node['openstack']['admin_password']}\" #{node['openstack']['admin_user']}"
    environment keystone_test_env
end

# Create the admin role:
execute 'create_admin_role' do
    command 'openstack role create admin'
    environment keystone_test_env
end

# Add the admin role to the admin project and user:
execute 'bind_admin_role' do
    command "openstack role add --project admin --user #{node['openstack']['admin_user']} admin"
    environment keystone_test_env
end

# This guide uses a service project that contains a unique user for each service that you add to your environment.
# Create the service project:
execute 'create_service_project' do
    command 'openstack project create --domain default --description "Service Project" service'
    environment keystone_test_env
end

# Regular (non-admin) tasks should use an unprivileged project and user.
# As an example, this guide creates the demo project and user.
# Create the demo project:
execute 'create_demo_project' do
    command 'openstack project create --domain default --description "User Project" demo'
    environment keystone_test_env
end
# Create the demo user:
execute 'create_demo_user' do
    command 'openstack user create --domain default --password "secret" demo'
    environment keystone_test_env
end
# Create the user role:
execute 'create_user_role' do
    command 'openstack role create user'
    environment keystone_test_env
end
# Add the user role to the demo project and user:
execute 'bind_user_role' do
    command 'openstack role add --project demo --user demo user'
    environment keystone_test_env
end


# Verify operation
execute 'admin_token' do
    command 'openstack token issue'
    environment admin_env
end
execute 'user_token' do
    command 'openstack token issue'
    environment user_env
end



###########################
# GLANCE
###########################

include_recipe 'openstack::glance'

# create the service credentials
# Create the glance user:
execute 'glance_user' do
    command "openstack user create --domain default --password \"#{node['openstack']['glance']['password']}\" #{node['openstack']['glance']['username']}"
    environment admin_env
end
# Add the admin role to the glance user and service project:
execute 'bind_glance_role' do
    command "openstack role add --project service --user #{node['openstack']['glance']['username']} admin"
    environment admin_env
end
# Create the glance service entity:
execute 'glance_service_entity' do
    command "openstack service create --name glance --description \"OpenStack Image\" image"
    environment admin_env
end

# Create the Image service API endpoints:
execute 'glance_endpoint_public' do
    command "openstack endpoint create --region RegionOne image public http://controller:9292"
    environment admin_env
end
execute 'glance_endpoint_internal' do
    command "openstack endpoint create --region RegionOne image internal http://controller:9292"
    environment admin_env
end
execute 'glance_endpoint_admin' do
    command "openstack endpoint create --region RegionOne image admin http://controller:9292"
    environment admin_env
end

# Populate the Image service database:
execute 'populate_glance' do
    command "su -s /bin/sh -c \"glance-manage db_sync\" #{node['openstack']['glance']['db_name']}"
end

# Finalize installation
service 'glance-registry' do
    action [ :restart ]
end
service 'glance-api' do
    action [ :restart ]
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
end
execute 'glance_image_list' do
    command "openstack image list"
    environment admin_env
end

###########################
# NOVA
###########################

include_recipe "openstack::nova"

# create the service credentials
# Create the nova user:
execute 'nova_user' do
    command "openstack user create --domain default --password \"#{node['openstack']['nova']['password']}\" #{node['openstack']['nova']['username']}"
    environment admin_env
end
# Add the admin role to the nova user:
execute 'bind_nova_user' do
    command "openstack role add --project service --user #{node['openstack']['nova']['username']} admin"
    environment admin_env
end
# Create the nova service entity:
execute 'nova_service_entity' do
    command "openstack service create --name nova --description \"OpenStack Compute\" compute"
    environment admin_env
end

# Create the Compute service API endpoints:
execute 'nova_endpoint_public' do
    command "openstack endpoint create --region RegionOne compute public http://controller:8774/v2.1/%\\(tenant_id\\)s"
    environment admin_env
end
execute 'nova_endpoint_internal' do
    command "openstack endpoint create --region RegionOne compute internal http://controller:8774/v2.1/%\\(tenant_id\\)s"
    environment admin_env
end
execute 'nova_endpoint_admin' do
    command "openstack endpoint create --region RegionOne compute admin http://controller:8774/v2.1/%\\(tenant_id\\)s"
    environment admin_env
end
# Populate the Compute databases:
execute 'populate_nova_api_db' do
    command "su -s /bin/sh -c \"nova-manage api_db sync\" nova"
    environment admin_env
end
execute 'populate_nova_db' do
    command "su -s /bin/sh -c \"nova-manage db sync\" nova"
    environment admin_env
end
# Finalize installation
service 'nova-api' do
    action [ :restart ]
end
service 'nova-consoleauth' do
    action [ :restart ]
end
service 'nova-scheduler' do
    action [ :restart ]
end
service 'nova-conductor' do
    action [ :restart ]
end
service 'nova-novncproxy' do
    action [ :restart ]
end

# Verify operation
execute 'verify_nova_operation' do
    command "openstack compute service list"
    environment admin_env
end


###########################
# NEUTRON
###########################

include_recipe "openstack::neutron"

# create the service credentials
# Create the neutron user:
execute 'neutron_service_credentials' do
    command "openstack user create --domain default --password \"#{node['openstack']['neutron']['password']}\" #{node['openstack']['neutron']['username']}"
    environment admin_env
end
# Add the admin role to the neutron user:
execute 'bind_neutron_role' do
    command "openstack role add --project service --user #{node['openstack']['neutron']['username']} admin"
    environment admin_env
end
# Create the neutron service entity:
execute 'neutron_service_entity' do
    command "openstack service create --name neutron --description \"OpenStack Networking\" network"
    environment admin_env
end

# Create the Networking service API endpoints:
execute 'neutron_endpoint_public' do
    command "openstack endpoint create --region RegionOne network public http://controller:9696"
    environment admin_env
end
execute 'neutron_endpoint_internal' do
    command "openstack endpoint create --region RegionOne network internal http://controller:9696"
    environment admin_env
end
execute 'neutron_endpoint_admin' do
    command "openstack endpoint create --region RegionOne network admin http://controller:9696"
    environment admin_env
end

# Finalize installation
# Populate the database:
execute 'populate_neutron_db' do
    command "su -s /bin/sh -c \"neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head\" neutron"
    environment admin_env
end

service 'nova-api' do
    action [ :restart ]
end
service 'neutron-server' do
    action [ :restart ]
end
service 'neutron-linuxbridge-agent' do
    action [ :restart ]
end
service 'neutron-dhcp-agent' do
    action [ :restart ]
end
service 'neutron-metadata-agent' do
    action [ :restart ]
end
service 'neutron-l3-agent' do
    action [ :restart ]
end


# Verify operation
# execute 'neutron_loaded_extensionts' do
#     command "neutron ext-list"
#     environment admin_env
# end
# execute 'neutron_agent_list' do
#     command "neutron agent-list"
#     environment admin_env
# end

###########################
# HORIZON
###########################

include_recipe "openstack::horizon"

# execute 'populate_horizon_db' do
#     command "/usr/share/openstack-dashboard/manage.py syncdb"
#     environment admin_env
# end

service 'nova-api' do
    action [ :reload ]
end

service 'apache2' do
    action [ :reload ]
end
