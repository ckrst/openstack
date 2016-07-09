#

hostsfile_entry '10.0.0.11' do
    hostname 'controller'
    action :create_if_missing
end

hostsfile_entry '10.0.0.31' do
    hostname 'compute1'
    action :create_if_missing
end

package 'lvm2'
package 'cinder-volume'
