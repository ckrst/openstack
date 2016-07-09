[![Build Status](https://travis-ci.org/vinik/openstack.svg?branch=master)](https://travis-ci.org/vinik/openstack)

# openstack-cookbook

TODO: Enter the cookbook description here.

## Supported Platforms

TODO: List your supported platforms.

## Attributes

<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['openstack']['bacon']</tt></td>
    <td>Boolean</td>
    <td>whether to include bacon</td>
    <td><tt>true</tt></td>
  </tr>
</table>

## Usage

### openstack::default

Include `openstack` in your node's `run_list`:

```json
{
  "run_list": [
    "recipe[openstack::default]"
  ]
}
```

## License and Authors

Author:: YOUR_NAME (<YOUR_EMAIL>)
