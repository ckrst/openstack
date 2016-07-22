default['openstack']['admin_token'] = '71e444e5726be697906c'

default['openstack']['admin_user'] = 'cloudroot'
default['openstack']['admin_password'] = 'adminPass'

default['openstack']['release'] = 'mitaka'

#Networing
default['openstack']['nodes']['controller']['ipaddress'] = '10.0.0.11'
default['openstack']['nodes']['controller']['hostname'] = 'controller'

default['openstack']['nodes']['compute'][0]['ipaddress'] = '10.0.0.31'

default['openstack']['db']['root_password'] = 'secret'
default['openstack']['db']['host'] = '127.0.0.1'

default['openstack']['rabbitmq']['user'] = 'openstack'
default['openstack']['rabbitmq']['password'] = 'secret'

default['openstack']['keystone']['username'] = 'keystone'
default['openstack']['keystone']['password'] = 'secret'
default['openstack']['keystone']['db_name'] = 'keystone'
default['openstack']['keystone']['db_user'] = 'keystone'
default['openstack']['keystone']['db_pass'] = 'secret'

default['openstack']['cinder']['username'] = 'cinder'
default['openstack']['cinder']['password'] = 'secret'
default['openstack']['cinder']['db_name'] = 'cinder'
default['openstack']['cinder']['db_user'] = 'cinder'
default['openstack']['cinder']['db_pass'] = 'secret'

default['openstack']['glance']['username'] = 'glance'
default['openstack']['glance']['password'] = 'secret'
default['openstack']['glance']['db_name'] = 'glance'
default['openstack']['glance']['db_user'] = 'glance'
default['openstack']['glance']['db_pass'] = 'secret'

default['openstack']['neutron']['username'] = 'neutron'
default['openstack']['neutron']['password'] = 'secret'
default['openstack']['neutron']['db_name'] = 'neutron'
default['openstack']['neutron']['db_user'] = 'neutron'
default['openstack']['neutron']['db_pass'] = 'secret'

default['openstack']['nova']['username'] = 'nova'
default['openstack']['nova']['password'] = 'secret'
default['openstack']['nova']['db_name'] = 'nova'
default['openstack']['nova_api']['db_name'] = 'nova_api'
default['openstack']['nova']['db_user'] = 'nova'
default['openstack']['nova']['db_pass'] = 'secret'

default['openstack']['horizon']['db_name'] = 'dash'
default['openstack']['horizon']['db_user'] = 'dash'
default['openstack']['horizon']['db_pass'] = 'secret'
