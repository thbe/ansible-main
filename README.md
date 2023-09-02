# Ansible configuration management

[![Linter](https://github.com/thbe/ansible-main/actions/workflows/linter.yml/badge.svg)](https://github.com/thbe/ansible-main/actions/workflows/linter.yml)

This is a small proof of concept to perform an initial management of new installed RedHat nodes using Kickstart and Ansible.

## Table of Contents

- [Ansible configuration management](#ansible-configuration-management)
  - [Table of Contents](#table-of-contents)
  - [Prerequisite](#prerequisite)
    - [Initialize Ansible repositories](#initialize-ansible-repositories)
    - [Update repositories](#update-repositories)
    - [Ansible Galaxy roles and collections](#ansible-galaxy-roles-and-collections)
    - [Ansible configuration](#ansible-configuration)
  - [Ad hoc execution](#ad-hoc-execution)
  - [Automated playbook execution](#automated-playbook-execution)
  - [Azure playbook execution](#azure-playbook-execution)
  - [SAP playbook execution](#sap-playbook-execution)
  - [Directory layout (best practice)](#directory-layout-best-practice)
  - [Provisioning workflow](#provisioning-workflow)
    - [Base system](#base-system)

## Prerequisite

### Initialize Ansible repositories

The Ansible main template use two additional directories besides ansible-main in the operational root directory. This is ansible-results and ansible-inventory-XXX where XXX stands for the company or branch or region or whatever is associated with the inventory. In my case it looks like this:

```shell
ansible-inventory-thbe/
ansible-main/
ansible-results/
```

First, you need to create the base directory where all your Ansible scripts will be stored. This could be for example ***/srv/ansible***. Next, you need to have the Github CLI installed to use gh. Switch into the newly created directory and initialize the ansible-main directory:

```shell
gh repo clone thbe/ansible-main
```

```shell
mkdir ansible-results
cd ansible-results
mkdir aide cis lynis permissions rkhunter
cd ../ansible-main
git submodule update --init --recursive
cd playbooks/security/results
ln -s ../../../../ansible-results/aide .
ln -s ../../../../ansible-results/cis .
ln -s ../../../../ansible-results/lynis .
ln -s ../../../../ansible-results/permissions .
ln -s ../../../../ansible-results/rkhunter .
```

```shell
gh repo clone XXXX/ansible-inventory-XXX
```

### Update repositories

You need to have Oh-My-ZSH installed to use the GIT shortcuts.

```shell
cd ansible-inventory-XXX
ggl
cd ../ansible-main
ggl
git submodule update --remote
gaa
gcsm 'Update roles and playbooks'
ggf
```

### Ansible Galaxy roles and collections

Mandatory:

```shell
ansible-galaxy install -r requirements.yml -p roles/
ansible-galaxy collection install -r requirements.yml
```

Optional:

```shell
ansible-galaxy install redhat_sap.sap_rhsm
ansible-galaxy install redhat_sap.sap_hana_cockpit_deployment
ansible-galaxy install redhat_sap.sap_hana_deployment
ansible-galaxy install redhat_sap.sap_hana_ha_pacemaker
ansible-galaxy install redhat_sap.sap_hana_hsr
ansible-galaxy install redhat_sap.sap_hostagent
ansible-galaxy install redhat_sap.sap_netweaver_ha_pacemaker
ansible-galaxy install redhat_sap.sap_s4hana_deployment
```

Upgrade:

```shell
ansible-galaxy install thbe.common -p roles/ --force-with-deps --verbose
ansible-galaxy install thbe.rhel -p roles/ --force-with-deps --verbose
ansible-galaxy install thbe.security -p roles/ --force-with-deps --verbose
ansible-galaxy install thbe.baseline -p roles/ --force-with-deps --verbose
ansible-galaxy install thbe.sap -p roles/ --force-with-deps --verbose
```

### Ansible configuration

```ini
[defaults]
# Disable cows
nocows = true

# Run on 50 nodes in parallel
forks = 50

# Use faster strategy
# strategy = free

# Increase fact check timeout
gather_timeout = 30

# Enable host key checking
host_key_checking = true

# Use root on the remote nodes instead of local user
remote_user = ansible

# Standard path to inventory
inventory = /srv/ansible/ansible-main

# Allow switch from root to normal user
pipelining = true

# Use the YAML callback plugin.
stdout_callback = yaml

# Use the stdout_callback when running ad-hoc commands.
bin_ansible_callbacks = false

# Set verbosity
verbosity = 0

# Disable debug
debug = false

# Profiling
callbacks_enabled = timer, profile_tasks, profile_roles

[ssh_connection]
# Configure SSH optimization
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
```

## Ad hoc execution

Replace [name] with the correct environment name.

```shell
ansible -i inventories/[name]/hosts.yml all -m ping
ansible -i inventories/[name]/hosts.yml all -m setup
ansible -i inventories/[name]/hosts.yml all -a "/bin/date"
ansible -i inventories/[name]/hosts.yml all -a "/bin/hostname"
ansible -i inventories/[name]/hosts.yml all -a "/bin/uptime"
ansible -i inventories/[name]/hosts.yml all -a "/bin/free -h"
ansible -i inventories/[name]/hosts.yml all -m shell -a "/bin/ps aux | /bin/grep chronyd"
ansible -i inventories/[name]/hosts.yml all -b -m dnf -a "name=* state=latest"
ansible -i inventories/[name]/hosts.yml all -b -m service -a "name=ntpd state=started enabled=yes"
```

## Automated playbook execution

```shell
ansible-playbook -i inventories/<name>/hosts.yml site.yml
ansible-playbook -i inventories/<name>/hosts.yml playbooks/generic/reboot_hosts.yml
ansible-playbook -i inventories/<name>/hosts.yml playbooks/generic/upgrade.yml
```

## Azure playbook execution

Execute the playbooks in the given order to prepare a Azure VM:

```shell
ansible-playbook -i inventories/<name>/hosts.yml playbooks/rhel/subscription_registration.yml \
                 --extra-vars 'rhn_activation_key=key rhn_organization_id=id' --limit host_ip/ group
ansible-playbook -i inventories/<name>/hosts.yml playbooks/rhel/rhc_register.yml \
                 --extra-vars 'rhn_activation_key=key rhn_organization_id=id' --limit host_ip/ group
ansible-playbook -i inventories/<name>/hosts.yml playbooks/rhel/insights_register.yml --limit host_ip/ group
ansible-playbook -i inventories/<name>/hosts.yml playbooks/rhel/upgrade.yml --extra-vars 'rhel_release_version=version' --limit host_ip/ group
ansible-playbook -i inventories/<name>/hosts.yml site.yml
```

Fix the broken GPT tables on the root disk of the Azure VM:

```shell
ansible -i inventories/<name>/hosts.yml all -a "/opt/rhel/bin/fix_Azure_RHEL_OS_disk_layout.sh" --limit host_ip/ group
```

Deploy the new disk layout, upgrade and reboot the new Azure VM:

```shell
ansible-playbook -i inventories/<name>/hosts.yml playbooks/rhel/disks/os_setup.yml --limit host_ip/ group
ansible-playbook -i inventories/<name>/hosts.yml playbooks/generic/reboot.yml --limit host_ip/ group
```

Clean up and reporting:

```shell
ansible-playbook -i inventories/<name>/hosts.yml playbooks/rhel/dnf_autoremove.yml --limit host_ip/ group
ansible-playbook -i inventories/<name>/hosts.yml playbooks/rhel/insights_run.yml --limit host_ip/ group
ansible-playbook -i inventories/<name>/hosts.yml playbooks/rhel/rhc_status.yml --limit host_ip/ group
ansible-playbook -i inventories/<name>/hosts.yml playbooks/rhel/subscription_refresh.yml --limit host_ip/ group
```

## SAP playbook execution

For use as ASCS/ dialog instance execute the following playbook:

```shell
ansible-playbook -i inventories/<name>/hosts.yml playbooks/rhel/disks/sap_setup.yml --limit host_ip/ group
```

For use as HANA instance execute the following playbook:

```shell
ansible-playbook -i inventories/<name>/hosts.yml playbooks/rhel/disks/sap_setup.yml --limit host_ip/ group
ansible-playbook -i inventories/<name>/hosts.yml playbooks/rhel/disks/hana_setup.yml --limit host_ip/ group
```

For use shared NFS volumes execute the following playbook:

```shell
ansible-playbook -i inventories/<name>/hosts.yml playbooks/rhel/disks/shared_setup.yml --limit host_ip/ group
```

## Directory layout (best practice)

```text
inventories/
  environment_name/
    hosts.yml             # inventory file for production.yml environment
    group_vars/
      all.yml             # here we assign variables to all groups
      group1.yml          # here we assign variables to particular groups
      group2.yml
    host_vars/
      hostname1/
        main.yml          # here we assign variables to particular systems
      hostname2/
        main.yml

library/                  # if any custom modules, put them here (optional)
module_utils/             # if any custom module_utils to support modules, put them here (optional)
filter_plugins/           # if any custom filter plugins, put them here (optional)

site.yml                  # master playbook

roles/
  common/               # this hierarchy represents a "role"
    vars/
      main.yml            # variables associated with this role
        defaults/
            main.yml      # default lower priority variables for this role
        meta/
            main.yml      # role dependencies
        library/          # roles can also include custom modules
        module_utils/     # roles can also include custom module_utils
        lookup_plugins/   # or other types of plugins, like lookup in this case
    tasks/
      main.yml            # main task file, includes specific tasks
    handlers/
      service.yml         # handler files
    templates/            # files for use with the template resource
      motd.conf.j2        # templates end in .j2
    files/
      bar.txt             # files for use with the copy resource
      foo.sh              # script files for use with the script resource

  platform/               # the same kind of structure as "common" structure above
  rhel/                   # the same kind of structure as "common" structure above
  security/               # the same kind of structure as "common" structure above
  baseline/               # the same kind of structure as "common" structure above
  sap/                    # the same kind of structure as "common" structure above
```

## Provisioning workflow

### Base system

Add new VMs to inventories/[name]/hosts.yml and create the host-specific configuration under host_vars. Then register the VMs in the RedHat network:

```shell
ansible-playbook -i inventories/[name]/hosts.yml playbooks/rhel/subscription_registration.yml --extra-vars 'rhn_user=USER_ID rhn_password=PW' --limit "host_ip1, host_ip2, host_ip3"
```

Ensure that a proper subscription is assigned to the newly registered VMs. Continue with the RHC and Insights registration:

```shell
ansible-playbook -i inventories/[name]/hosts.yml playbooks/rhel/rhc_register.yml --extra-vars 'rhn_user=USER_ID rhn_password=PW' --limit "host_ip1, host_ip2, host_ip3"
ansible-playbook -i inventories/[name]/hosts.yml playbooks/rhel/insights_register.yml --extra-vars 'rhn_user=USER_ID rhn_password=PW' --limit "host_ip1, host_ip2, host_ip3"
```

The next step is to deploy the standard roles for the new VMs:

```shell
ansible-playbook -i inventories/[name]/hosts.yml site.yml
```

Due to a logic change in one of the package deployments, the initial run sometimes fails on new machines. To fix this, the respective machine needs to be upgraded. After the upgrade the standard roles will apply without an error:

```shell
ansible-playbook -i inventories/<name>/hosts.yml playbooks/rhel/dnf_upgrade.yml --limit "host_ip1, host_ip2, host_ip3"
ansible-playbook -i inventories/<name>/hosts.yml site.yml
```

The VMs are now configured with all relevant base settings.
