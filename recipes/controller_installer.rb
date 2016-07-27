


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

###########################
# GLANCE
###########################

include_recipe 'openstack::glance'

###########################
# NOVA
###########################

include_recipe "openstack::nova"


###########################
# NEUTRON
###########################

include_recipe "openstack::neutron"

###########################
# HORIZON
###########################

include_recipe "openstack::horizon"

#########################
#
#########################
