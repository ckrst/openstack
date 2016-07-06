#
# Cookbook Name:: openstack
# Recipe:: default
#
# Copyright (C) 2016 YOUR_NAME
#
# All rights reserved - Do Not Redistribute
#

package 'software-properties-common'

apt_repository 'cloud-archive:mitaka'

package 'python-openstackclient'
package 'mariadb-server'
package ' python-pymysql'

file '/etc/mysql/conf.d/openstack.cnf' do
    content '
[mysqld]
bind-address = 10.0.0.11

[mysqld]
default-storage-engine = innodb
innodb_file_per_table
collation-server = utf8_general_ci
character-set-server = utf8
'
end

package 'mongodb-server'
package 'mongodb-clients'
package 'python-pymongo'


package 'rabbitmq-server'


package 'memcached'
package 'python-memcache'
