require 'chefspec'
require 'chefspec/berkshelf'

at_exit { ChefSpec::Coverage.report! }

describe 'openstack::default' do
    let (:chef_run) { ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04').converge(described_recipe) }

    it 'converges successfully' do
        expect { chef_run }.to_not raise_error
    end

end
