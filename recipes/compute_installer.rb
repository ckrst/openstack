
include_recipe "openstack::compute"

# Restart the Compute service
execute 'restart_nova_compute' do
  command 'service nova-compute restart'
end

execute 'restart_neutron_agent' do
  command 'service neutron-linuxbridge-agent restart'
end
