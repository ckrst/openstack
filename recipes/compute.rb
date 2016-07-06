#

package 'nova-compute'

# TODO: full nova.conf content
file '/etc/nova/nova.conf' do
    content '
...
[cinder]
os_region_name = RegionOne
...
'
end

package 'neutron-linuxbridge-agent'
