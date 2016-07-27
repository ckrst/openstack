tag 'keystone'

keystone_test_env = {
    "OS_TOKEN"                  => node['openstack']['admin_token'],
    "OS_URL"                    => "http://#{node['openstack']['nodes']['controller']['hostname']}:35357/v3",
    "OS_IDENTITY_API_VERSION"   => "3"
}

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

user_env = {
    "OS_PROJECT_DOMAIN_NAME" => "default",
    "OS_USER_DOMAIN_NAME" => "default",
    "OS_PROJECT_NAME" => "demo",
    "OS_USERNAME" => "demo",
    "OS_PASSWORD" => "secret",
    "OS_AUTH_URL" => "http://#{node['openstack']['nodes']['controller']['hostname']}:5000/v3",
    "OS_IDENTITY_API_VERSION" => "3",
    "OS_IMAGE_API_VERSION" => "2"
}

mysql_connection_info = {
    :host     => node['openstack']['db']['host'],
    :username => 'root',
    :password => node['openstack']['db']['root_password']
}

mysql_database node['openstack']['keystone']['db_name'] do
  connection mysql_connection_info
  action :create
end

mysql_database_user node['openstack']['keystone']['db_user'] do
  connection mysql_connection_info
  password   node['openstack']['keystone']['db_pass']
  action     :create
end
mysql_database_user node['openstack']['keystone']['db_user'] do
  connection    mysql_connection_info
  password      node['openstack']['keystone']['db_pass']
  database_name node['openstack']['keystone']['db_name']
  host          '%'
  privileges    [:all]
  action        :grant
end
mysql_database_user node['openstack']['keystone']['db_user'] do
  connection    mysql_connection_info
  password      node['openstack']['keystone']['db_pass']
  database_name node['openstack']['keystone']['db_name']
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

template "/etc/keystone/keystone.conf" do
    source 'keystone.conf.erb'
    mode '0644'
    owner 'root'
    group 'root'
end


# Initialize Fernet keys (to run once and only after populate db)
execute 'initialize_fernet_keys' do
    command "keystone-manage fernet_setup --keystone-user #{node['openstack']['keystone']['username']} --keystone-group #{node['openstack']['keystone']['username']}"
    action :nothing
end

# Populate the Identity service database
execute 'populate_keystone' do
    command "su -s /bin/sh -c \"keystone-manage db_sync\" #{node['openstack']['keystone']['db_name']} && touch /root/.osc/keystone_db_ok"
    not_if { File.exists?("/root/.osc/keystone_db_ok") }
    notifies :run, 'execute[initialize_fernet_keys]', :immediately
end


#APACHE
package 'apache2' do
    options '--force-yes'
    action :install
end
package 'libapache2-mod-wsgi' do
    options '--force-yes'
    action :install
end

template "/etc/apache2/sites-available/wsgi-keystone.conf" do
    source 'wsgi-keystone.erb'
    mode '0644'
    owner 'root'
    group 'root'
end

service 'apache2'

link '/etc/apache2/sites-enabled/wsgi-keystone.conf' do
  to '/etc/apache2/sites-available/wsgi-keystone.conf'
  link_type :symbolic
  notifies :restart, 'service[apache2]', :immediately
end

# By default, the Ubuntu packages create an SQLite database. Because this configuration uses an SQL database server, you can remove the SQLite database file:
file '/var/lib/keystone/keystone.db' do
    action :delete
end


# Create the service entity for the Identity service
execute 'create_keystone_entity' do
    command "openstack service create --name keystone --description \"OpenStack Identity\" identity"
    environment keystone_test_env
    not_if "openstack service show keystone"
end

# Create the Identity service API endpoints
execute 'create_keystone_public_endpoint' do
    command "openstack endpoint create --region RegionOne identity public http://#{node['openstack']['nodes']['controller']['hostname']}:5000/v3"
    environment keystone_test_env
    not_if "openstack endpoint list --service keystone --interface public | grep public"
end
execute 'create_keystone_internal_endpoint' do
    command "openstack endpoint create --region RegionOne identity internal http://#{node['openstack']['nodes']['controller']['hostname']}:5000/v3"
    environment keystone_test_env
    not_if "openstack endpoint list --service keystone --interface internal | grep internal"
end
execute 'create_keystone_admin_endpoint' do
    command "openstack endpoint create --region RegionOne identity admin http://#{node['openstack']['nodes']['controller']['hostname']}:35357/v3"
    environment keystone_test_env
    not_if "openstack endpoint list --service keystone --interface admin | grep admin"
end

# Create a domain, projects, users, and roles

# Create the default domain
execute 'create_default_domain' do
    command 'openstack domain create --description "Default Domain" default'
    environment keystone_test_env
    not_if "openstack domain show default"
end

# Create an administrative project, user, and role for administrative operations in your environment
# Create the admin project:
execute 'create_admin_project' do
    command 'openstack project create --domain default --description "Admin Project" admin'
    environment keystone_test_env
    not_if "openstack project show admin"
end

# Create the admin user:
execute 'create_admin_user' do
    command "openstack user create --domain default --password \"#{node['openstack']['admin_password']}\" #{node['openstack']['admin_user']}"
    environment keystone_test_env
    not_if "openstack user show #{node['openstack']['admin_user']}"
end


# Add the admin role to the admin project and user: (to be executed after create_admin_role)
execute 'bind_admin_role' do
    command "openstack role add --project admin --user #{node['openstack']['admin_user']} admin"
    environment keystone_test_env
    action :nothing
end

# Create the admin role:
execute 'create_admin_role' do
    command 'openstack role create admin'
    environment keystone_test_env
    not_if "openstack role show admin"
    notifies :run, "execute[bind_admin_role]", :immediately
end

# This guide uses a service project that contains a unique user for each service that you add to your environment.
# Create the service project:
execute 'create_service_project' do
    command 'openstack project create --domain default --description "Service Project" service'
    environment keystone_test_env
    not_if "openstack project show service"
end

# Regular (non-admin) tasks should use an unprivileged project and user.
# As an example, this guide creates the demo project and user.
# Create the demo project:
execute 'create_demo_project' do
    command 'openstack project create --domain default --description "User Project" demo'
    environment keystone_test_env
    not_if "openstack project show demo"
end

# Create the demo user:
execute 'create_demo_user' do
    command 'openstack user create --domain default --password "secret" demo'
    environment keystone_test_env
    not_if "openstack user show demo"
end

# Add the user role to the demo project and user: (to be executed after create_user_role)
execute 'bind_user_role' do
    command 'openstack role add --project demo --user demo user'
    environment keystone_test_env
    action :nothing
end

# Create the user role:
execute 'create_user_role' do
    command 'openstack role create user'
    environment keystone_test_env
    not_if "openstack role show user"
    notifies :run, "execute[bind_user_role]", :immediately
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
