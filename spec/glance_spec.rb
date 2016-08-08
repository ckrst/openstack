require 'chefspec'
require 'chefspec/berkshelf'

describe 'openstack::glance' do
    let (:chef_run) {
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04', log_level: :fatal).converge(described_recipe)
    }

    before do
        stub_command("openstack user show glance").and_return(0)
        stub_command("openstack service show glance").and_return(1)
        stub_command("openstack endpoint list --service glance --interface public | grep public").and_return(1)
        stub_command("openstack endpoint list --service glance --interface internal | grep internal").and_return(1)
        stub_command("openstack endpoint list --service glance --interface admin | grep admin").and_return(1)
        stub_command("openstack image show ubuntu").and_return(1)
    end

    it 'converges successfully' do
        expect { chef_run }.to_not raise_error
    end

    it 'create_mysql_database("glance")' do
        chef_run.converge(described_recipe)
        expect(chef_run).to create_mysql_database("glance")
    end

    it 'create_mysql_database_user("glance")' do
        chef_run.converge(described_recipe)
        expect(chef_run).to create_mysql_database_user("glance")
    end

    it 'install_package("glance")' do
        chef_run.converge(described_recipe)
        expect(chef_run).to install_package("glance")
    end

    it 'create_template("/etc/glance/glance-api.conf")' do
        chef_run.converge(described_recipe)
        expect(chef_run).to create_template("/etc/glance/glance-api.conf")
    end

    it 'create_template("/etc/glance/glance-registry.conf")' do
        chef_run.converge(described_recipe)
        expect(chef_run).to create_template("/etc/glance/glance-registry.conf")
    end

    # it 'run_execute("bind_glance_role")' do
    #     chef_run.converge(described_recipe)
    #     expect(chef_run).to run_execute("bind_glance_role")
    # end

    it 'run_execute("glance_user")' do
        chef_run.converge(described_recipe)
        expect(chef_run).to run_execute("glance_user")
    end

    # it 'run_execute("glance_service_entity")' do
    #     chef_run.converge(described_recipe)
    #     expect(chef_run).to run_execute("glance_service_entity")
    # end
    #
    # it 'run_execute("glance_endpoint_public")' do
    #     chef_run.converge(described_recipe)
    #     expect(chef_run).to run_execute("glance_endpoint_public")
    # end
    #
    # it 'run_execute("glance_endpoint_internal")' do
    #     chef_run.converge(described_recipe)
    #     expect(chef_run).to run_execute("glance_endpoint_internal")
    # end
    #
    # it 'run_execute("glance_endpoint_admin")' do
    #     chef_run.converge(described_recipe)
    #     expect(chef_run).to run_execute("glance_endpoint_admin")
    # end
    #
    # it 'create_service("glance-registry")' do
    #     chef_run.converge(described_recipe)
    #     expect(chef_run).to create_service("glance-registry")
    # end
    #
    # it 'create_service("glance-api")' do
    #     chef_run.converge(described_recipe)
    #     expect(chef_run).to create_service("glance-api")
    # end
    #
    # it 'run_execute("populate_glance")' do
    #     chef_run.converge(described_recipe)
    #     expect(chef_run).to run_execute("populate_glance")
    # end
    #
    # it 'create_directory("/glance_images")' do
    #     chef_run.converge(described_recipe)
    #     expect(chef_run).to create_directory("/glance_images")
    # end
    #
    # it 'create_remote_file("/glance_images/trusty-server-cloudimg-amd64-disk1.img")' do
    #     chef_run.converge(described_recipe)
    #     expect(chef_run).to create_remote_file("/glance_images/trusty-server-cloudimg-amd64-disk1.img")
    # end
    #
    # it 'run_execute("import_ubuntu")' do
    #     chef_run.converge(described_recipe)
    #     expect(chef_run).to run_execute("import_ubuntu")
    # end
    #
    # it 'run_execute("glance_image_list")' do
    #     chef_run.converge(described_recipe)
    #     expect(chef_run).to run_execute("glance_image_list")
    # end




end
