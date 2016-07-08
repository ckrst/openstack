mysql_connection_info = {
    :host     => '127.0.0.1',
    :username => 'root',
    :password => 'secret'
}

mysql_database 'cinder' do
  connection mysql_connection_info
  action :create
end

mysql_database_user 'cinder' do
  connection mysql_connection_info
  password   'secret'
  action     :create
end
mysql_database_user 'cinder' do
  connection    mysql_connection_info
  password      'secret'
  database_name 'cinder'
  host          '%'
  privileges    [:all]
  action        :grant
end
mysql_database_user 'cinder' do
  connection    mysql_connection_info
  password      'secret'
  database_name 'cinder'
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
