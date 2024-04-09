# ANM ITOps Playbooks

This is a collection of playbooks for ANM ITOps automation

- [Setup](#setup)
  - [General Setup](#general-setup)
  - [Create Inventory](#create-inventory)
- [Playbooks](#playbooks)
  - [`update_snmp_acl`](#update_snmp_acl)
  - [`create_accounts`](#create_accounts)


## Setup
### General Setup
**If using from a VASA**, setup is automatic. This repo is cloned to /opt/ansible_local/anm_itops_playbooks. You can force an update by running `bash /opt/anm_ms_ova/sync_anm_itops_playbooks.sh` from the WSL console.

**If not on a VASA,** set up manually:
1. Clone this repo to /opt/ansible_local/anm_itops_playbooks
2. Install the dependencies by running `bash install_requirements.sh`


### Create Inventory
Create one or more inventory files in the inventory folder. See `inventory/default_inventory` for an example.

to create an inventory from MS customer assets use the Splunk dashboard: https://splunk.awscloud.anm.com/en-US/app/splunk_ms_app/ansible_inventory


## Playbooks
### `update_snmp_acl`
This playbook updates the SNMP ACL on one or more devices to allow this host's IP address.

**Variables**   
- `snmp_string`: The SNMP string to use

**Examples**   
```bash
ansible-playbook update_snmp_acl.yml -e "snmp_string=public" -u admin -k
```

-------------------------------------------------

### `create_accounts`
This playbook creates/ updates ot deletes accounts on one or more devices.

**Variables**   
- `update_password` (optional): If set to "always", the password will be updated, even if the user already exists. If not defined passwords will only be set for new users
- `remove_user` (optional): If set to a username, the user will be removed from the device.
- `add_user` (optional): If set to a username, the user will be added to the device.  
- `add_password` (required for `add_user` and `update_password`): The password to set for the user.
  
**Examples**   
Add a user
```bash
ansible-playbook playbooks/create_accounts.yml -e "add_user=testuser add_password=testpassword" -u admin -k
```

Remove a user
```bash
ansible-playbook playbooks/create_accounts.yml -e "remove_user=testuser" -u admin -k
```

Update a user's password
```bash
ansible-playbook playbooks/create_accounts.yml -e "update_password=always add_user=testuser add_password=testpassword" -u admin -k
```
