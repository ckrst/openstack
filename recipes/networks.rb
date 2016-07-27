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

execute 'provider_network' do
    command "neutron net-create --shared --provider:physical_network provider --provider:network_type flat provider"
    environment admin_env
    not_if "neutron net-show provider"
end

execute 'provider_subnetwork' do
    command "neutron subnet-create --name provider --allocation-pool start=10.40.199.20,end=10.40.199.199 --dns-nameserver 8.8.8.8 --gateway 10.40.0.1 provider 10.40.0.0/16"
    environment admin_env
    not_if "neutron subnet-show provider"
end

execute 'selfservice_network' do
    command "neutron net-create selfservice"
    environment admin_env
    not_if "neutron net-show selfservice"
end

execute 'selfservice_subnetwork' do
    command "neutron subnet-create --name selfservice --dns-nameserver 8.8.8.8 --gateway 192.168.10.10 selfservice 192.168.10.0/24"
    environment admin_env
    not_if "neutron subnet-show selfservice"
end

execute 'add_router_to_provider_network' do
    command "neutron net-update provider --router:external"
    environment admin_env
    not_if "neutron net-show provider -c router:external | grep True"
end

execute 'add_ssnetwork_subnet_as_router_interface' do
    command "neutron router-interface-add router selfservice"
    environment admin_env
    action :nothing
end
execute 'set_gateway_provider_network' do
    command "neutron router-gateway-set router provider"
    environment admin_env
    action :nothing
end

execute 'create_router' do
    command "neutron router-create router"
    environment admin_env
    not_if "neutron router-show router"
    notifies :run, 'execute[add_ssnetwork_subnet_as_router_interface]', :immediately
    notifies :run, 'execute[set_gateway_provider_network]', :immediately
end
