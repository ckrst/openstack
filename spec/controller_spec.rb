require 'chefspec'
require 'chefspec/berkshelf'

describe 'openstack::controller' do
    let (:chef_run) {
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04', log_level: :fatal).converge(described_recipe)
    }

    it 'converges successfully' do
        expect { chef_run }.to_not raise_error
    end

    it 'create osc dir' do
        chef_run.converge(described_recipe)
        expect(chef_run).to create_directory("/root/.osc")
    end

    it 'remove odd loopback' do
        chef_run.converge(described_recipe)
        expect(chef_run).to remove_hostsfile_entry("127.0.1.1")
    end

    it 'add controller to hostsfile' do
        chef_run.converge(described_recipe)
        expect(chef_run).to create_hostsfile_entry_if_missing("10.0.0.11")
    end

    it 'install package software-properties-common' do
        chef_run.converge(described_recipe)
        expect(chef_run).to install_package("software-properties-common")
    end

    it 'add mitaka repository' do
        chef_run.converge(described_recipe)
        expect(chef_run).to add_apt_repository("cloudarchive-mitaka")
    end

    it 'install package python-openstackclient' do
        chef_run.converge(described_recipe)
        expect(chef_run).to install_package('python-openstackclient')
    end

    it 'install mysql' do
        chef_run.converge(described_recipe)
        expect(chef_run).to create_mysql_service 'default'
    end

    it 'start mysql' do
        chef_run.converge(described_recipe)
        expect(chef_run).to start_mysql_service 'default'
    end

    it 'create mysql config openstack_defaults' do
        chef_run.converge(described_recipe)
        expect(chef_run).to create_mysql_config 'openstack_defaults'
    end

    it 'install mysql2_chef_gem default' do
        chef_run.converge(described_recipe)
        expect(chef_run).to install_mysql2_chef_gem 'default'
    end

    it 'install package python-pymysql' do
        chef_run.converge(described_recipe)
        expect(chef_run).to install_package 'python-pymysql'
    end

    it 'include mongo' do
        chef_run.converge(described_recipe)
        expect(chef_run).to include_recipe "mongodb"
    end

    it 'include rabbitmq' do
        chef_run.converge(described_recipe)
        expect(chef_run).to include_recipe "rabbitmq"
    end

    it 'add rabbitmq user' do
        chef_run.converge(described_recipe)
        expect(chef_run).to add_rabbitmq_user('openstack').with_password("secret")
    end

    it 'add rabbitmq user permissions' do
        chef_run.converge(described_recipe)
        expect(chef_run).to set_permissions_rabbitmq_user('openstack')
    end

    it 'create adminrc file' do
        chef_run.converge(described_recipe)
        expect(chef_run).to create_file('/root/admin-openrc')
    end

    it 'create userrc file' do
        chef_run.converge(described_recipe)
        expect(chef_run).to create_file('/root/demo-openrc')
    end

    it 'install memcached' do
        chef_run.converge(described_recipe)
        expect(chef_run).to install_package 'memcached'
    end

    it 'create memcached conf' do
        chef_run.converge(described_recipe)
        expect(chef_run).to create_file '/etc/memcached.conf'
    end

end
