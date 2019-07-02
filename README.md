# Ansible Roles: Mesosphere DC/OS

A set of Ansible Roles that manage a DC/OS cluster lifecycle on RedHat/CentOS Linux.

## Requirements

To make best use of these roles, your nodes should resemble the Mesosphere recommended way of setting up infrastructure. Depending on your setup, it is expected to deploy to:

* One or more master node ('masters')
* One bootstrap node ('bootstraps')
* Zero or more agent nodes, used for public facing services ('agents_public')
* One or more agent nodes, not used for public facing services ('agents_private')
* Zero or more windows agent nodes ('agents_windows')
### An example inventory file is provided as shown here:

```ini
[bootstraps]
bootstrap1-dcos112s.example.com

[masters]
master1-dcos112s.example.com
master2-dcos112s.example.com
master3-dcos112s.example.com

[agents_private]
agent1-dcos112s.example.com
remoteagent1-dcos112s.example.com

[agents_public]
publicagent1-dcos112s.example.com

[agents_windows]
agent1-windows.example.com  ansible_user=Administrator  ansible_password=<mysecurepassword1>
agent2-windows.example.com  ansible_user=Administrator  ansible_password=<mysecurepassword2>

[agents:children]
agents_private
agents_public

[common:children]
bootstraps
masters
agents
agents_public
```

## Role Variables

The Mesosphere DC/OS Ansible roles make use of two sets of variables:

1. A set of per-node type `group_var`'s
2. A multi-level dictionary called `dcos`, that should be available to all nodes

### Per group vars

```ini
[bootstraps:vars]
node_type=bootstrap

[masters:vars]
node_type=master
dcos_legacy_node_type_name=master

[agents_private:vars]
node_type=agent
dcos_legacy_node_type_name=slave

[agents_public:vars]
node_type=agent_public
dcos_legacy_node_type_name=slave_public

[agents_windows:vars]
ansible_connection=winrm
ansible_winrm_transport=basic
ansible_winrm_server_cert_validation=ignore
```

### Global vars

```yml
dcos:
  download: "https://downloads.dcos.io/dcos/stable/1.13.1/dcos_generate_config.sh"
  version: "1.13.1"
  enterprise_dcos: false
  selinux_mode: enforcing

  config:
    cluster_name: "examplecluster"
    security: strict
    bootstrap_url: http://int-bootstrap1-examplecluster.example.com:8080
    exhibitor_storage_backend: static
    master_discovery: static
    master_list:
      - 172.31.42.1
```

#### Cluster wide variables

| Name                    | Required?    | Description                                                                                                                                                                                                                                        |
|:------------------------|:-------------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| download                | REQUIRED     | (https) URL to download the Mesosphere DC/OS install from                                                                                                                                                                                          |
| version                 | REQUIRED     | Version string that reflects the version that the installer (given by `download`) installs. Can be collected by running `dcos_generate_config.sh --version`.                                                                                       |
| version_to_upgrade_from | for upgrades | Version string of Mesosphere DC/OS the upgrade procedure expectes to upgrade FROM. A per-version upgrade script will be generated on the bootstrap machine, each cluster node downloads the proper upgrade for its currenly running DC/OS version. |
| image_commit            | no           | Can be used to force same version / same config upgrades. Mostly useful for deploying/upgrading non-released versions, e.g. `1.12-dev`. This parameter takes precedence over `version`.                                                            |
| enterprise_dcos         | REQUIRED     | Specifies if the installer (given by `download`) installs an 'open' or 'enterprise' version of Mesosphere DC/OS. This is required as there are additional post-upgrade checks for enterprise-only components.                                      |
| selinux_mode            | REQUIRED     | Indicates the cluster nodes operating sytems SELinux mode. Mesosphere DC/OS supports running in `enforcing` mode starting with **1.12**. Older versions require `permissive`.                                                                      |
|                         |              |                                                                                                                                                                                                                                                    |
| config                  | yes          | Yaml structure that represents a valid Mesosphere DC/OS config.yml, see below.                                                                                                                                                                     |

#### DC/OS config.yml parameters
Please see [the official Mesosphere DC/OS configuration reference](https://docs.mesosphere.com/1.13/installing/production/advanced-configuration/configuration-reference/) for a full list of possible parameters.
There are a few parameters that are used by these roles outside the DC/OS config.yml, specifically:

* `bootstrap_url`: Should point to http://*your bootstrap node*:8080. Will be used internally and conviniently overwritten for the installer/upgrader to point to a version specific sub-directory.
* `ip_detect_contents`: Is used to determine a user-supplied IP detection script. Overwrites the build-in enviroment detection and usage of a generic AWS and/or on premise script. [Official Mesosphere DC/OS ip-detect reference](https://docs.mesosphere.com/1.13/installing/production/deploying-dcos/installation/#create-an-ip-detection-script)
* `ip_detect_public_contents`: Is used to determine a user-supplied public IP detection script. Overwrites the build-in enviroment detection and usage of a generic AWS and/or on premise script. [Official Mesosphere DC/OS ip-detect reference](https://docs.mesosphere.com/1.13/installing/production/deploying-dcos/installation/#create-an-ip-detection-script)
* `fault_domain_detect_contents`: Is used to determine a user-supplied fault domain detection script. Overwrites the build-in enviroment detection and usage of a generic AWS and/or on premise script.

#### Ansible dictionary merge behavior caveat

Due to the nested structure of the `dcos` configuration, it might be required to set Ansible to ['merge' instead of 'replace'](https://docs.ansible.com/ansible/2.4/intro_configuration.html#hash-behaviour), when combining config from multiple places.

##### Example

```ini
# ansible.cfg
hash_behaviour = merge
```

#### Safeguard during interactive use: `dcos_cluster_name_confirmed`

When invoking these roles interactively (for example from the operator's machine), the `DCOS.bootstrap` role will require a manual confirmation of the cluster to run against. This is a safeguarding mechanism to avoid unintentional upgrade or config changes. In non-interactive plays, a variable can be set to skip this step, e.g.:

```bash
ansible-playbook -e 'dcos_cluster_name_confirmed=True' dcos.yml
```

## Example playbook

Mesosphere DC/OS is a complex system, spanning multiple nodes to form a full multi-node cluster. There are some constraints in making a playbook use the provided roles:

1. Order of groups to run their respective roles on (e.g. bootstrap node first, then masters, then agents)
2. Concurrency for upgrades (e.g. `serial: 1` for master nodes)

The provided `dcos.yml` playbook can be used as-is for installing and upgrading Mesosphere DC/OS.

## Tested OS and Mesosphere DC/OS versions

* CentOS 7, RHEL 7,  Windows Server ver. 1809 Datacenter Edition Server Core
* DC/OS 1.13, both open as well as enterprise version

## License

[Apache 2.0](http://www.apache.org/licenses/LICENSE-2.0)

## Author Information

This role was created by team SRE @ Mesosphere and others in 2018, based on multiple internal tools and non-public Ansible roles that have been developed internally over the years.
