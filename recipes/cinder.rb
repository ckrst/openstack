tag 'cinder'

mysql_connection_info = {
    :host     => node['openstack']['db']['host'],
    :username => 'root',
    :password => node['openstack']['db']['root_password']
}

mysql_database node['openstack']['cinder']['db_name'] do
  connection mysql_connection_info
  action :create
end

mysql_database_user node['openstack']['cinder']['db_user'] do
  connection mysql_connection_info
  password   node['openstack']['cinder']['db_pass']
  action     :create
end
mysql_database_user node['openstack']['cinder']['db_user'] do
  connection    mysql_connection_info
  password      node['openstack']['cinder']['db_pass']
  database_name node['openstack']['cinder']['db_name']
  host          '%'
  privileges    [:all]
  action        :grant
end
mysql_database_user node['openstack']['cinder']['db_user'] do
  connection    mysql_connection_info
  password      node['openstack']['cinder']['db_pass']
  database_name node['openstack']['cinder']['db_name']
  host          'localhost'
  privileges    [:all]
  action        :grant
end

package 'cinder-api' do
    options '--force-yes'
end
package 'cinder-scheduler' do
    options '--force-yes'
end
