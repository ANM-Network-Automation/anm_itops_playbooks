# ANM ITOps Playbooks

This is a collection of playbooks for ANM ITOps automation

- [ANM ITOps Playbooks](#anm-itops-playbooks)
  - [**Setup**](#setup)
    - [**General Setup**](#general-setup)
    - [**Create Inventory**](#create-inventory)
    - [**Splunk Inventory**](#splunk-inventory)
  - [**Playbooks**](#playbooks)
    -  `update_snmp_acl`, `create_accounts`, `configure_snmpv3`, `remove_snmp`, `http_server`
    - [**Upgrades**](#upgrades): `get_platform_series`, `disk_clean_up`, `prestage-ios_iosxe`, `upgrade-ios_iosxe`
    - [**Config**](#config):
      - [**AAA**](#aaa): `tacacs`, `radius`, `coa_config`, `automate_tester`, `set_radius_global_settings`
      - [**Services:**](#services) `dns`, `igmp_snooping`, `ip_sla`, `logging`, `netflow`, `ntp`, `qos`
      - [**SNMP:**](#snmp) `v2c`, `v3`
    - [**Verify:**](#verify) `cred_validation`,`custom`, `device_discovery`, `verify_clock`, `verify_dns`, `verify_license`, `verify_spanning_tree`, `verify_vlans`
  - [**Scripts**](#scripts): `iis.ps1`, `excel_to_mputty_xml.py`
  - [**Procedures**](#procedures): `Upgrade Prestage`, `Configure AAA TACACS`, `Configure AAA RADIUS`, `Onboarding`

## Setup
### General Setup
**If using from a VASA**, setup is automatic. This repo is cloned to /opt/ansible_local/anm_itops_playbooks. You can force an update by running `bash /opt/anm_ms_ova/sync_anm_itops_playbooks.sh` from the WSL console.

**If not on a VASA,** set up manually:
1. Clone this repo to /opt/ansible_local/anm_itops_playbooks
2. Install the dependencies by running `bash install_requirements.sh`


### Create Inventory
Create one or more inventory files in the inventory folder. See `inventory/default_inventory` for an example.

to create an inventory from MS customer assets use the Splunk dashboard: https://splunk.awscloud.anm.com/en-US/app/splunk_ms_app/ansible_inventory

You can target a host or \[group\] by adding `--limit HOST_OR_GROUP` to the ansible-playbook command

### Splunk Inventory
#### Inventory Info
Splunk Inventory will use an excel sheet downloaded from Splunk to dynamically create the inventory used by playbooks. This plug in will automatically create groups for devices based on whether it is a switch, router, etc. As well as a group based on the platform series. A devices platform series is grouped because many different types of devices are technically the same series and therefore use the same software image. For example, Catalyst 9300, 9500, 9407, 9406 are all part of the platform series c9000, meaning all of these devices will use the same software image (cat9k). While the current inventory is comprehensive, grouping of platform series is still in work in progress as we come across different device types.

The Splunk inventory script is automatically used when you run a playbook from the /opt/ansible_local/anm_itops_playbooks folder (this is where ansible.cfg is located and used). However, you can directly pass in the inventory by itself if needed using:
```
-i '/opt/ansible_local/anm_itops_playbooks/inventory/excel_python.py'
```

To view the inventory directly, you can run:
```
./inventory/excel_inventory.py
```

You can target specific hosts/groups to run the playbook. You can use a single group, multiple groups, single host, multiple hosts, combination groups/hosts. You split the differing variables with a comma (,) no space, for example:
Single Group: switches
Multiple Group: switches,routers,firewalls
Single Host: switch1
Multiple Host: switch1,switch2,router2
Combination: switches,router1

When using a group, all devices associated to that group will be targeted. 

When running playbooks, if -l or --limit is omitted from teh command, all hosts will be targeted by the playbook. 

Since the script uses the inventory directly from Splunk, it is best to obtain the names of the hosts that you wish to run a playbook on directly from SNOW CMDB, since the hostnames in SNOW should match those in Splunk.

By default, ansible-playbook will use all available inventory files available in inventory/ folder.

#### Download Excel File
1. Open the Splunk inventory link and log in (can be done on the VASA/PASA):

    [Splunk](https://splunk.awscloud.anm.com/en-US/app/splunk_ms_app/lm_device_explorer?form.COMPANY=*&form.FIELDS=displayName&form.FIELDS=sn.sys_class_name&form.FIELDS=auto.anm_model&form.FIELDS=auto.anm_os&form.FIELDS=auto.anm.firmware&form.FIELDS=sn.u_anm_support_level&form.CLASS=cmdb_ci_ip_router&form.CLASS=cmdb_ci_ip_switch&form.CLASS=cmdb_ci_ip_firewall&form.CLASS=u_cmdb_ci_fmc&form.CLASS=u_cmdb_ci_wireless_controller&form.CLASS=u_cmdb_ci_ise_acs&form.SEARCH=*%20sn.u_anm_support_level!%3D%22Retired%22%20sn.u_anm_support_level!%3D%22Not%20Supported%22%20sn.u_anm_support_level!%3D%22Offboarded%22)


2. Set **Company** and remove `All` from the company field.

3. Verify the following fields are present:

- `displayName`  
- `sn.sys_class_name`  
- `auto.network.address`  
- `auto.anm_os`  
- `auto.anm_model`  
- `auto.anm_firmware`  
- `sn.u_anm_support_level`  

4. Verify the following classes are present:

- `cmdb_ci_ip_router`  
- `cmdb_ci_ip_switch`  
- `cmdb_ci_ip_firewall`
- `u_cmdb_ci_fmc`
- `u_cmdb_ci_wireless_controller`
- `u_cmdb_ci_ise_acs`

5. Verify search/filter is present:

```
sn.u_anm_support_level!="Retired" sn.u_anm_support_level!="Not Supported" sn.u_anm_support_level!="Offboarded"
```

6. **Download XLSX**:

- Click on "Download Device List"
- This will download a file named "lm_devices.xlsx"
- rename file to "inventory.xlsx"

7. Move the file to the following Folder in Linux WSL:

```
/opt/ansible_local/anm_itops_playbooks/inventory
```
8. Test by running the following from a WSL cmd
```
cd /opt/ansible_local/anm_itops_playbooks
./inventory/excel_inventory.py
```
This should return an output similar to the following:
```
{
    "_meta": {
        "hostvars": {
            "switch1": {
                "ansible_host": "1.1.1.1",
                "platform_series": "c9000",
                "pid": "c9300-48p",
                "ansible_network_os": "ios",
                "ansible_connection": "network_cli",
                "platform_os": "ios_xe",
                "auto.anm.firmware": "17.6.4"
            },
            "switch2": {
                "ansible_host": "2.2.2.2",
                "platform_series": "c9000",
                "pid": "c9410r",
                "ansible_network_os": "ios",
                "ansible_connection": "network_cli",
                "platform_os": "ios_xe",
                "auto.anm.firmware": "17.12.4"
            "firewall1": {
                "ansible_host": "3.3.3.3",
                "platform_series": "asa5506",
                "pid": "asa5506",
                "ansible_network_os": "asa",
                "ansible_connection": "network_cli",
                "platform_os": "asa",
                "auto.anm.firmware": "9.8.2"
            }
        }
    },
    "switch": {
        "hosts": [
            "firewall1",
            "switch1",
            "switch2"
        ]
    },
    "c9000": {
        "hosts": [
            "switch1",
            "switch2",
        ]
    },
    "firewall": {
        "hosts": [
            "firewall1",
        ]
    "asa5506": {
        "hosts": [
            "firewall1"
        ]
    },
    }
}
```

#### Inventory Troubleshooting
* For many issues that may come up regarding inventory, the number 1 thing to check is that the inventory.xlsx exists in the inventory folder. 

## Playbooks
<details>
<summary>update_snmp_acl</summary>
  
### `update_snmp_acl`
This playbook updates the SNMP ACL on one or more devices to allow this host's IP address.

**Supported OS:**   
* IOS
* IOS/XE
* NX-OS
* FTD (via FDM)

**Variables**   
- `snmp_string` (required) The SNMP string to use
- `enable_secret` (Optional): enable secret if device requires it
- `collector_ips` (Optional): List type. Allows for multiple IP addresses of collectors to be passed separated by commas
- `collector_ip` (Optional): Allows for single IP addresses to be passed

**Examples**   
```bash
ansible-playbook playbooks/update_snmp_acl.yml -i inventory.ini -e 'snmp_string=public enable_secret=SOMESECRET' --limit network -u admin -k
```
Add a list of collectors
```bash
ansible-playbook playbooks/update_snmp_acl.yml -i inventory.ini -u admin -k -e 'collector_ips="1.2.3.4,1.2.3.5,1.2.3.6" snmp_string=welcome1'
```
</details>
-------------------------------------------------

<details>
<summary>create_accounts</summary>
  
### `create_accounts`
This playbook creates/ updates ot deletes accounts on one or more devices.

**Variables**   
- `update_password` (optional): If set to "always", the password will be updated, even if the user already exists. If not defined passwords will only be set for new users
- `remove_user` (optional): If set to a username, the user will be removed from the device.
- `add_user` (optional): If set to a username, the user will be added to the device.  
- `add_password` (required for `add_user` and `update_password`): The password to set for the user.
- `enable_secret`: Optional: enable secret if device requires it
  
**Examples**   
Add a user
```bash
ansible-playbook playbooks/create_accounts.yml -e 'add_user=testuser add_password=testpassword enable_secret=SOMESECRET' --limit network -u admin -k
```

Remove a user
```bash
ansible-playbook playbooks/create_accounts.yml -e 'remove_user=testuser enable_secret=SOMESECRET' --limit network -u admin -k
```

Update a user's password
```bash
ansible-playbook playbooks/create_accounts.yml -e 'update_password=always add_user=testuser add_password=testpassword enable_secret=SOMESECRET' --limit network -u admin -k
```
</details>
-------------------------------------------------
<details>
<summary>configure_snmpv3</summary>
  
### `configure_snmpv3`
This playbook creates a readonly group and configures a snmpv3 user

**Variables**   
- `snmpv3_user` (required): Username of the snmpv3 user to be given access
- `auth_password` (required): SHA encrypted password. This is NOT the plaintext password.
- `privacy_password` (required): AES 128 encrypted privacy password. This is NOT the plaintext password.
- `enable_secret` (optional): enable secret if device requires it
  
**Examples**   
Add a user
```bash
ansible-playbook configure_snmpv3.yml -e 'snmpv3_user=testuser auth_password=Ab39NnC4N3acYABat7AD privacy_password=Ah7Dbh7ABCDARx7nNAjJ enable_secret=SOMESECRET' --limit network -u admin -k

```
</details>
-------------------------------------------------
<details>
<summary>remove_snmp</summary>
  
### `remove_snmp`
This playbook removes snmp community strings from the device

**Supported OS:**  
* IOS
* IOS/XE
* NX-OS

**Variables**   
- `snmp_string` (required): The SNMP string to use
- `enable_secret` (optional): enable secret if device requires it
  
**Examples**   
Remove snmpv2 community from a device
```bash
ansible-playbook remove_snmp.yml -e 'snmp_string=welcome1' --limit network -u admin -k

```
</details>
-------------------------------------------------
<details>
<summary>http_server</summary>

### `http_server`
This playbook adds an ACL to an existing http-server enabled switch. Also supports removing the http-server config

**Supported OS**    
* IOS
* IOS/XE

**Variables**   
- `acl_ips`: (Required if remove not set): Type List of string. These are the subnets that will be put into the ACL. Example. acl_ips=["10.16.0.0 0.0.255.255", "10.17.0.0 0.0.255.255"]
- `acl_name`: (Required if remove not set): Type string. The name of the ACL that will be applied to the http-server
- `remove`: (Required if acl_ips and acl_name are not set): Type bool. Set to "true" to remove the http-server config from the switch. This is mutually exclusive to the acl_ips and acl_name variables. Do not set this and acl_ips/acl_name.
- `enable_secret`: (Optional): enable secret if device requires it
  
**Examples**   
Add new ACL to a device with acl_ips defined in inventory.ini
```bash
ansible-playbook http_server.yml -i inventory.ini -e acl_name=test_acl --limit network -u admin -k

```
Add new ACL to a device with acl_ips defined on CLI
```bash
ansible-playbook http_server.yml -i inventory.ini -e 'acl_name=test_acl acl_ips=["10.16.0.0 0.0.255.255", "10.17.0.0 0.0.255.255"]' --limit network -u admin -k

```
Remove http-server config from device
```bash
ansible-playbook http_server.yml -i inventory.ini -e 'remove=true' --limit network -u admin -k
```
</details>
-------------------------------------------------

### Upgrades

<details>
<summary>View Upgrade Playbooks</summary>

- 
  <details>
  <summary>get_platform_series</summary>
    
  #### `get_platform_series`
  This playbook shows the platform series from inventory, i.e. c9000. It is used as a pre step for upgrades and helps to minimize the amount of discovery needed to prepare for downloading images.

  **Supported OS:**   
  * All

  **Variables**   
  Remember to use -l or --limit to run playbook on specific hosts/groups: Example: -l 'switch,router' will return the platform series for all devices belonging to groups switch or router.

  **Examples**   
  Shows platform series for all hosts/groups
  ```bash
  ansible-playbook playbooks/upgrades/get_platform_series.yml
  ```
  Shows platform series for switch/router group
  ```bash
  ansible-playbook playbooks/upgrades/get_platform_series.yml -l 'switch,router'
  ```

  Output:
  ```bash
  TASK [Show platform for selected hosts/groups] ********************************************************************************************************************************************************************
  ok: [switch1] =>
    hostvars[inventory_hostname]["platform_series"]: c9000
  ok: [switch2] =>
    hostvars[inventory_hostname]["platform_series"]: c2960x
  ok: [switch3] =>
    hostvars[inventory_hostname]["platform_series"]: c2960x
  ok: [switch4] =>
    hostvars[inventory_hostname]["platform_series"]: c9000
  ok: [firewall1] =>
    hostvars[inventory_hostname]["platform_series"]: asa5506

  TASK [Show platform series for selected hosts/groups] *************************************************************************************************************************************************************
  ok: [sw1] =>
    msg: |-
      Platform series in use:
      - asa5506
      - c2960x
      - c9000
  ```

  The Task named "Show platform for selected hosts/groups" will show the platform series for each device
  The task named "Show platform series for selected hosts/groups" will show the combined platform series for the hosts/groups.

  In this example, you would then go to Cisco software download and download the image for 2960x, c9000, and asa5506. Downloading those 3 will cover all devices' software requirements.
  </details>
-------------------------------------------------
- 
  <details>
  <summary>disk_clean_up</summary>
    
  #### `disk_clean_up`
  This playbook will clean up the disk on a device. Used primarily for prestaging to ensure a device is ready to download a new image. This should be ran prior to any upload as this script will delete an image that is not currently active.
  For devices in bundle mode, script will delete the following patterns (the script will not delete the currently running image):
            - '^crashinfo'
            - '\.log$'
            - '\.old$'
            - '\.prv$'
            - '\.xml$'
            - '\.bin$'
            - '\.tar$'
            
  For devices in install mode, script will delete the following patterns as well as run "install remove inactive":
            - '^crashinfo'
            - '\.log$'
            - '\.old$'
            - '\.prv$'
            - '\.xml$'

  **Supported OS:**   
  * IOS (bundle mode)
  * IOS XE (bundle/install mode)

  **Variables**  
  - If these variables are not passed in via the -e argument, they will be prompted for during the script execution
  - Remember to use -l or --limit to run playbook on specific hosts/groups: Example: -l 'switch,router' will clean the disk for all devices belonging to groups switch or router.
  - `ansible_user` (required): Username to log in to devices
  - `ansible_password` (required): Password to log in to devices (if a device does not log into a device in enable, this same password will be tried for enable mode)
  - `enable` (optional): Enable password for higher privileges, defaults to ansible_password when not defined
  - `confirm` (required): When running this script, a confirmation is required before deleting files, if running using passed -e, this var is required for afk operation.

  **Examples**   
  Cleans disk image for hosts in the c9200l, c2960x, or c9000 groups
  ```bash
  ansible-playbook playbooks/upgrades/disk_clean_up.yml -l 'c9200l,c2960x,c9000' -e 'ansible_user=user' -e 'ansible_password=password' -e 'confirm=yes'
  ```

  Output:
  ```bash
  PLAY [Disk Clean UP Playbook] *************************************************************************************************************************************************************************************
  ...
  REDACTED OUTPUT - Tasks in this section are unimportant
  ...
  TASK [Show device mode] *******************************************************************************************************************************************************************************************
  ok: [sw1] =>
    msg: Device is running in install mode
  ok: [sw2] =>
    msg: Device is running in bundle mode
  ok: [sw3] =>
    msg: Device is running in install mode
  ok: [sw4] =>
    msg: Device is running in install mode
  ...
  REDACTED OUTPUT - Tasks in this section are unimportant
  ...
  TASK [Show matched files] *****************************************************************************************************************************************************************************************
  ok: [sw1] =>
    msg: |-
      Found 0 matching files:
  ok: [sw2] =>
    msg: |-
      Found 0 matching files:
  ok: [sw3] =>
    msg: |-
      Found 1 matching files:
      - smart_overall_health.log
  ok: [sw4] =>
    msg: |-
      Found 1 matching files:
      - smart_overall_health.log

  TASK [Cleaning up unnecessary package files] **********************************************************************************************************************************************************************
  ok: [sw1]
  ok: [sw2]
  ok: [sw3]

  TASK [Delete matching files] **************************************************************************************************************************************************************************************
  ok: [sw3]
  ok: [sw4]
  ```
  Install remove inactive is being run on devices in install mode under the task named "Cleaning up unnecessary package files"

  </details>
-------------------------------------------------

- 
  <details>
  <summary>prestage-ios_iosxe</summary>
    
  #### `prestage-ios_iosxe`
  This playbook will upload the required image via http and verify md5 of the file. The playbook will first check to make sure the device is not currently running the target version then make sure that the device has enough disk space before attempting the upload. Playbook can be run multiple times on devices due to safety checks. A previously successful device will not redownload the image for example.

  **Summary/Overview of tasks:**  
  * Server check: Ensures that the http and folder are reachable, playbook will not continue if server is not reachable.
  * Backs Up device config to /opt/ansible_local/anm_itops_playbooks/backup
  * Version Check: If a device is already running the target version, the device will be marked as complete.
  * Disk Space Check: If a device does not have enough space for new image, it will be marked as failed. Rest of tasks will be skipped
  * Check for current image in flash: Playbook will check if the software image is already on the device, if it is, it will skip upload and only verify MD5
  * Upload Image: After Tasks to assert device does not have the image, the playbook may seem to freeze, the first batch of devices will begin the image copy and no output or progress will be shown during this time. You are free to walk away.
  * Verify MD5: After upload (or if image is already on disk), the playbook will verify the image MD5. 
  * Output: If all tasks complete successfully, each device will show the verified output, as well as the command needed to install/update the software for later use.

  **Supported OS:**  
  * IOS (bundle mode)
  * IOS XE (bundle/install mode)

  **Variables**  
  If these variables are not passed in via the -e argument, they will be prompted for during the script execution
  Remember to use -l or --limit to run playbook on specific hosts/groups: Example: -l 'switch,router' will prestage for all devices belonging to groups switch or router..
  - `ansible_user` (required): Username to log in to devices
  - `ansible_password` (required): Password to log in to devices (if a device does not log into a device in enable, this same password will be tried for enable mode)
  - `enable` (optional): Enable password for higher privileges, defaults to ansible_password when not defined
  - `http_server` (required): The IP address of the http server i.e 10.10.10.10

  **Examples**   
  Starts prestage process for devices in the c9200l group, using http server 1.1.1.1
  ```bash
  ansible-playbook playbooks/upgrades/prestage-ios_iosxe.yml -l "c9200l" -e "ansible_user=user" -e 'ansible_password=password' -e "http_server=1.1.1.1"
  ```

  Output:
  ```bash
  PLAY [Prompt for variables if needed] *****************************************************************************************************************************************************************************
  ...
  REDEACTED
  ...

  TASK [Debug all device facts] *************************************************************************************************************************************************************************************
  ok: [sw1] =>
    msg: |-
      Device Configuration Facts:
      ========================
      Device Mode: bundle
      Target Image: c2960x-universalk9-tar.152-7.E13.tar
      Target Image MD5: 56604f86ee9b096b3deb622b52062f6b
      Target Image Size: 41574400
      Target Image Size KB: 41574.4
      Target Version: 15.2(7)E13
      Flash Directory: flash:
      Timestamp: 2025-11-06
      Current Version: 15.2(2)E7
      IOS Type: IOS
      Device Upgraded: False
      Dir Image Check:
      Free Space: 94977024

  TASK [Config Backup /opt/ansible_local/anm_itops_playbooks/backup] ************************************************************************************************************************************************
  changed: [sw1]

  TASK [Check running image] ****************************************************************************************************************************************************************************************
  ok: [sw1] => changed=false
    msg: METRO-ROMA-SW not running target version 15.2(7)E13, current version is 15.2(2)E7

  TASK [Assert Enough Disk Space Available] *************************************************************************************************************************************************************************
  ok: [sw1] => changed=false
    msg: Enough disk space is available to accommodate target image.

  TASK [Assert flash: does NOT contain target image before copy] ****************************************************************************************************************************************************
  ok: [sw1] => changed=false
    msg: 'c2960x-universalk9-tar.152-7.E13.tar NOT in flash:'

  TASK [Copy IOSXE image file via HTTP] *****************************************************************************************************************************************************************************
  ok: [sw1]

  ...
  REDACTED
  ...

  TASK [output results] *********************************************************************************************************************************************************************************************
  ok: [sw1] =>
    msg: |-
      MD5 - ['Done!', 'Verified (flash:c2960x-universalk9-tar152-7E13tar) = 56604f86ee9b096b3deb622b52062f6b']
      To upgrade use: archive download-sw flash:c2960x-universalk9-tar.152-7.E13.tar

  ```


  **Troubleshooting** 

  Troubleshooting can be categorized based on which task was failed for a device. For any failed device, I would create a list of failed devices, fix the issues, then run the script again for those devices.
  * HTTP server check failure: Ensure that the http server is operational and working. If using IIS, make sure you can reach it successfully yourself by navigating to http://1.1.1.1/http, you should see the files listed on the browser if successful.
  * Disk Space Failure: Log into the device and clean up the disk space. This can be done manually or using the disk_clean_up playbook for the hosts that failed the disk space check i.e -e 'target_hosts=switch4,router1'
  * MD5 Failure: This indicates a corrupted image, best to log into device manually and delete the image then try again.
  * Errors during Upload: If you see errors related to IO errors during the upload task, this could indicate the device is unable to reach the server. Few things to check -
    - Ensure device can reach the http server, i.e telnet 1.1.1.1 80. If not working, check for ACLs or FW that could be blocking
    - The source http client interface could be set incorrectly. You can set this manually or use the http-source-int-update playbook to automatically set an http client source interface
    - The server could have been overloaded during the operation and refused connection. If the http server has high CPU, this could cause IO errors, simply rerunning with less hosts could be successful
  * Timeout or Failed to write to SSH Channel: These errors could be caused by an unreachable device or if uploading takes too long. Retry at a later time using same script. If issue persists, these devices will need to be manually prestaged.

  </details>
-------------------------------------------------

- 
  <details>
  <summary>upgrade-ios_iosxe</summary>
    
  #### `upgrade-ios_iosxe`
  This playbook will complete the upgrade on devices that we're prestaged previously.

  **Summary/Overview of tasks:**  
  * Loads the commands needed to start the upgrade from previous playbook vars
  * Writes the config to memory
  * Runs install command for IOS-XE devices (converts to install mode for IOS-XE devices running in bundle
  * Runs archive download-sw for bundle IOS devices
  * Waits for device to reboot and asserts that is running the new target version
    
  **Supported OS:**  
  * IOS (bundle mode)
  * IOS XE (bundle/install mode)

  **Variables**  
  If these variables are not passed in via the -e argument, they will be prompted for during the script execution
  Remember to use -l or --limit to run playbook on specific hosts/groups: Example: -l 'switch,router' will prestage for all devices belonging to groups switch or router..
  - `ansible_user` (required): Username to log in to devices
  - `ansible_password` (required): Password to log in to devices (if a device does not log into a device in enable, this same password will be tried for enable mode)
  - `enable` (optional): Enable password for higher privileges, defaults to ansible_password when not defined

  **Examples**   
  Starts upgrade process for devices in the c9200l group.
  ```bash
  ansible-playbook playbooks/upgrades/upgrade-ios_iosxe.yml -l "c9200l" -e "ansible_user=user" -e 'ansible_password=password'
  ```

  Output:
  ```bash

  ```

  **Troubleshooting**

  </details>
-------------------------------------------------

-  
  <details>
  <summary>http-source-int-update</summary>
    
  #### `http-source-int-update`
  This playbook will dynamically set the http client source interface based on whatever interface is using the SSH ip address. For example, if you successfully SSH to IP address 1.1.1.1, that means more than likely that the interface that is assigned with that IP can be used as the http client source. Running this on client devices will not break any other functionality since the http client source is only used for copy operations, which we own.

  **Supported OS:**  
  * IOS
  * IOS XE

  **Variables**  
  If these variables are not passed in via the -e argument, they will be prompted for during the script execution
  Remember to use -l or --limit to run playbook on specific hosts/groups: Example: -l 'switch,router' will update http client source interface for all devices belonging to groups switch or router.
  - `ansible_user` (required): Username to log in to devices
  - `ansible_password` (required): Password to log in to devices (if a device does not log into a device in enable, this same password will be tried for enable mode)
  - `enable` (optional): Enable password for higher privileges, defaults to ansible_password when not defined

  **Examples**   
  Updates the http client source interface to interface assigned with the IP used to successfully log into the device
  ```bash
  ansible-playbook playbooks/upgrades/http-source-int-update.yml -e "target_hosts=c9200l" -e "ansible_user=user" -e 'ansible_password=password'
  ```

  Output:
  ```bash
  PLAY [Prompt for variables if needed] *****************************************************************************************************************************************************************************
  ...
  REDACTED
  ...
  TASK [Set HTTP Source] ********************************************************************************************************************************************************************************************
  changed: [sw1]
  changed: [sw2]

  TASK [Verify HTTP source interface configuration (IOS)] ***********************************************************************************************************************************************************
  ok: [sw1]
  ok: [sw2]

  TASK [Consolidate http_config_verify results] *********************************************************************************************************************************************************************
  ok: [sw1]
  ok: [sw2]

  TASK [Display verification results] *******************************************************************************************************************************************************************************
  ok: [sw1] =>
    msg: |-
      Configuration Verification for 1.1.1.1:
      - Interface used: Loopback0
      - Configuration found: ip http client source-interface Loopback0
      - Status: SUCCESS
  ok: [sw2] =>
    msg: |-
      Configuration Verification for 2.2.2.2:
      - Interface used: Loopback0
      - Configuration found: ip http client source-interface Loopback0
      - Status: SUCCESS
  ```
  </details>
-------------------------------------------------
</details>
-------------------------------------------------

### Config

  #### AAA
-
  <details>
  <summary>View AAA Playbooks</summary>

  - 
    <details>
    <summary>tacacs</summary>

    ##### `tacacs`
    This playbook will dynamically configure TACACS on devices based on the servers configured in aaa-servers.yml.

    **Summary/Overview of tasks:**  
    * Configures AAA new-model if not configured - required for devices that are newly being configured
    * Grabs any current TACACS related configuration
    * Configures Specified tacacs servers in `/opt/ansible_local/anm_itops_playbooks/playbooks/config/aaa/vars/aaa-servers.yml` - Ensure to update aaa-servers.yml before attempting to run the playbook
    * Configures TACACS group with the organization_prefix + TACACS, example: ANM-TACACS. Places the configured TACACS servers in the group
    * Configures method lists with organization_prefix and the newly created TACACS group For example:
    ```bash
    aaa authentication login ANM_authc group ANM-TACACS local enable
    aaa authentication enable default group ANM-TACACS enable
    aaa authorization exec ANM_authz group ANM-TACACS local if-authenticated
    aaa accounting commands 1 default start-stop group ANM-TACACS
    aaa accounting commands 15 default start-stop group ANM-TACACS
    ```
    * Configures the VTY lines with the authentication and authorization method lists, for example:
    ```
    line vty 0 15
    login authentication ANM_authc
    authorization exec ANM_authz
    ```
    * Removes old and deprecated tacacs-server commands - tacacs-server commands are being removed in future releases, this task removes them and ensure we are only using named configs
    * Shows output after configuring

    **Supported OS:**  
    * IOS
    * IOS XE

    **Variables**
    If these variables are not passed in via the -e argument, they will be prompted for during the script execution
    Remember to use -l or --limit to run playbook on specific hosts/groups: Example: -l 'switch,router' will update TACACS for all devices belonging to groups switch or router.
    - `ansible_user` (required): Username to log in to devices
    - `ansible_password` (required): Password to log in to devices (if a device does not log into a device in enable, this same password will be tried for enable mode)
    - `enable` (optional): Enable password for higher privileges, defaults to ansible_password when not defined
    - `organization_prefix` (required): Prefix that will be appended to the TACACS group and AAA method lists
    - `tacacs_key` (required): The PSK used for the TACACS server
    - `group_name` (optional): Override the default tacacs group name to use a specific name instead of the one built using the organization_prefix var


    **Examples**   
    Configures TACACS on a single device. 
    ```bash
    ansible-playbook playbooks/config/aaa/tacacs.yml -l 'sw1' -e 'organization_prefix=ANM' -e 'ansible_user=user' -e 'ansible_password=password' -e 'tacacs_key=tacacs123'
    ```

    Output:
    ```bash
    ```
    </details>
  -------------------------------------------------

  - 
    <details>
    <summary>radius</summary>

    ##### `radius`
    This playbook will dynamically configure RADIUS on devices based on the servers configured in aaa-servers.yml. When no optional variables are used, the script configured RADIUS for use with dot1x/mab (network access) only. Special care must be taken when a client has both radius and tacacs available. Use the optional variables to configure login (device administration) using the same radius servers when not using tacacs for device administration. In environments with both protocols available, run this script to configure network access (dot1x/mab), then run tacacs script to configure device administration.

    **Summary/Overview of tasks:**  
    * Configures AAA new-model if not configured - required for devices that are newly being configured
    * Grabs any current RADIUS related configuration
    * Configures Specified radius servers in `/opt/ansible_local/anm_itops_playbooks/playbooks/config/aaa/vars/aaa-servers.yml` - Ensure to update aaa-servers.yml before attempting to run the playbook
    * Configures RADIUS group with the organization_prefix + RADIUS, example: ANM-RADIUS. Places the configured RADIUS servers in the group
    * Configures method lists with organization_prefix and the newly created TACACS group For example:
    ```bash
    aaa authentication login ANM_authc_radius group ANM-RADIUS local enable
    aaa authentication enable default group ANM-RADIUS enable
    aaa authorization exec ANM_authz__radius group ANM-RADIUS local if-authenticated
    aaa accounting commands 1 default start-stop group ANM-RADIUS
    aaa accounting commands 15 default start-stop group ANM-RADIUS
    ```
    * Configures the VTY lines with the authentication and authorization method lists, for example:
    ```
    line vty 0 15
    login authentication ANM_authc
    authorization exec ANM_authz
    ```
    * Removes old and deprecated tacacs-server commands - tacacs-server commands are being removed in future releases, this task removes them and ensure we are only using named configs
    * Shows output after configuring

    **Supported OS:**  
    * IOS
    * IOS XE

    **Variables**
    If these variables are not passed in via the -e argument, they will be prompted for during the script execution
    Remember to use -l or --limit to run playbook on specific hosts/groups: Example: -l 'switch,router' will update RADIUS for all devices belonging to groups switch or router.
    - `ansible_user` (required): Username to log in to devices
    - `ansible_password` (required): Password to log in to devices (if a device does not log into a device in enable, this same password will be tried for enable mode)
    - `enable` (optional): Enable password for higher privileges, defaults to ansible_password when not defined
    - `organization_prefix` (required): Prefix that will be appended to the RADIUS group and AAA method lists
    - `radius_key` (required): The PSK used for the RADIUS server
    - `timeout_seconds` (optional): Timeout in seconds, defaults to 3 seconds
    - `retry` (optional): Amount of times to retry, defaults to 3
    - `deadtime` (optional): Amount of time in minutes before trying a server marked dead again, defaults to 10 minutes
    - `load_balance` (optional): Sets load balancing of servers in the server group globally
    - `config_coa` (optional): Set to 'yes' to also configure COA for the same radius servers using the same key. Defaults to 'no'.
    - `config_tester` (optional): Set to 'yes' to also configure automate tester for the configured radius servers. Defaults to 'no'.
    - `config_login` (optional): Set to 'yes' to configure login and mab/dot1x. Defaults to 'no'.
    - `login_only` (optional): Set to 'yes' to ato only configure login. Defaults to 'no'.
    - `group_name` (optional): Override the default radius group name to use a specific name instead of the one built using the organization_prefix var
    - `config_avp` (optional): Sets RADIUS additional AVPs to be sent with the access-request message: attribute 6 on-for-login-auth, attribute 8 include-in-access-req, attribute 25 access-request include, attribute 31 mac format ietf, attribute 31 send nas-port-detail
    - `config_device_sensor` (optional): Configures device-sensor to send cdp, lldp, and dhcp information to the server using accounting messages.



    **Examples**   
    Configures RADIUS on a single device. 
    ```bash
    ansible-playbook playbooks/config/aaa/radius.yml -l 'sw1' -e 'organization_prefix=ANM' -e 'ansible_user=user' -e 'ansible_password=password' -e 'radius_key=radius123'
    ```

    Output:
    ```bash
    ```
    </details>
  -------------------------------------------------

  - 
    <details>
    <summary>coa_config</summary>

    ##### `coa_config`
    This playbook will add CoA config to a device based on the servers configured in aaa-servers.yml. This playbook should only be used when radius config is already present on devices.

    **Summary/Overview of tasks:**  
    * Grabs any current RADIUS related configuration
    * Configures Specified radius servers in `/opt/ansible_local/anm_itops_playbooks/playbooks/config/aaa/vars/aaa-servers.yml` as CoA servers - Ensure to update aaa-servers.yml before attempting to run the playbook. Playbooks will attempt to use the same key found in the devices config, otherwise the provided key will be used.
    * Shows output after configuring

    **Supported OS:**  
    * IOS
    * IOS XE

    **Variables**
    If these variables are not passed in via the -e argument, they will be prompted for during the script execution
    Remember to use -l or --limit to run playbook on specific hosts/groups: Example: -l 'switch,router' will update RADIUS for all devices belonging to groups switch or router.
    - `ansible_user` (required): Username to log in to devices
    - `ansible_password` (required): Password to log in to devices (if a device does not log into a device in enable, this same password will be tried for enable mode)
    - `enable` (optional): Enable password for higher privileges, defaults to ansible_password when not defined
    - `radius_key` (required): The PSK used for the RADIUS server

    **Examples**   
    Configures coA on a single device. 
    ```bash
    ansible-playbook playbooks/config/aaa/coa_config.yml -l 'sw1' -e 'ansible_user=user' -e 'ansible_password=password' -e 'radius_key=radius123'
    ```
    </details>
  -------------------------------------------------

  - 
    <details>
    <summary>automate_tester</summary>

    ##### `automate_tester`
    This playbook will add the automate-tester config to a device. 

    **Summary/Overview of tasks:**  
    * Grabs any current RADIUS related configuration
    * Configures Specified radius servers in `/opt/ansible_local/anm_itops_playbooks/playbooks/config/aaa/vars/aaa-servers.yml` with automate tester - Ensure to update aaa-servers.yml before attempting to run the playbook.
    * Shows output after configuring

    **Supported OS:**  
    * IOS
    * IOS XE

    **Variables**
    If these variables are not passed in via the -e argument, they will be prompted for during the script execution
    Remember to use -l or --limit to run playbook on specific hosts/groups: Example: -l 'switch,router' will update RADIUS for all devices belonging to groups switch or router.
    - `ansible_user` (required): Username to log in to devices
    - `ansible_password` (required): Password to log in to devices (if a device does not log into a device in enable, this same password will be tried for enable mode)
    - `enable` (optional): Enable password for higher privileges, defaults to ansible_password when not defined

    **Examples**   
    Configures automate-tester on a single device. 
    ```bash
    ansible-playbook playbooks/config/aaa/automate_tester.yml -l 'sw1' -e 'ansible_user=user' -e 'ansible_password=password'
    ```
    </details>
  -------------------------------------------------

  - 
    <details>
    <summary>set_radius_global_settings</summary>

    ##### `set_radius_global_settings`
    This playbook will add global radius settings:

    ```
              - "radius-server dead-criteria time {{ timeout }} tries {{ retries }}"
              - "radius-server retransmit {{ retries }}"
              - "radius-server timeout {{ timeout }}"
              - "radius-server deadtime{{ deadtime }}"
    ```

    **Supported OS:**  
    * IOS
    * IOS XE

    **Variables**
    If these variables are not passed in via the -e argument, they will be prompted for during the script execution
    Remember to use -l or --limit to run playbook on specific hosts/groups: Example: -l 'switch,router' will update RADIUS for all devices belonging to groups switch or router.
    - `ansible_user` (required): Username to log in to devices
    - `ansible_password` (required): Password to log in to devices (if a device does not log into a device in enable, this same password will be tried for enable mode)
    - `enable` (optional): Enable password for higher privileges, defaults to ansible_password when not defined
    - `timeout` (optional): Timeout in seconds, defaults to 3 seconds
    - `retries` (optional): Amount of times to retry, defaults to 3
    - `deadtime` (optional): Amount of time in minutes before trying a server marked dead again, defaults to 10 minutes
    - `load_balance` (optional): Sets load balancing of servers in the server group globally
    - `config_avp` (optional): Sets RADIUS additional AVPs to be sent with the access-request message: attribute 6 on-for-login-auth, attribute 8 include-in-access-req, attribute 25 access-request include, attribute 31 mac format ietf, attribute 31 send nas-port-detail
    - `config_device_sensor` (optional): Configures device-sensor to send cdp, lldp, and dhcp information to the server using accounting messages.


    **Examples**   
    Configures global settings on a single device. 
    ```bash
    ansible-playbook playbooks/config/aaa/set_radius_global_settings.yml -l 'sw1' -e 'ansible_user=user' -e 'ansible_password=password' -e 'timeout=5' -e 'deadtime=3' -e 'retries=4'
    ```
    </details>
  -------------------------------------------------

#### Services (PLACEHOLDER)
- 
  <details>
    <summary>View Services playbooks</summary>

    - 
      <details>
      <summary>dns</summary>

      </details>   
    - 
      <details>
      <summary>igmp_snooping</summary>

      </details>
    - 
      <details>
      <summary>ip_sla</summary>

      </details>

    - 
      <details>
      <summary>logging</summary>

      </details>

    - 
      <details>
      <summary>netflow</summary>

      </details>
    - 
      <details>
      <summary>ntp</summary>

      </details>

    - 
      <details>
      <summary>qos</summary>

      </details>
    </details>

#### SNMP

- 
  <details>
    <summary>View SNMP playbooks</summary>

    - 
      <details>
      <summary>v2c</summary>

      ##### `v2c`
        This playbook configures SNMP v2c with provided community string. AN ACL named "anm-ms-snmp-acl-std" is created/updated and applied to only allow snmp from the IPs specified in `./vars/jumpboxes.yml`. If jumpboxes.yml does not exist, you can copy jumpboxes-sample.yml and rename to jumpboxes.yml. You can then set the IPs for the jumpboxes like so:

        ```yaml
        snmp_allowed_ips:
          - 10.10.10.10
          - 10.10.10.20
          - 10.10.10.30
        ```

        **Supported OS:**  
        * IOS
        * IOS XE

        **Variables**
        If these variables are not passed in via the -e argument, they will be prompted for during the script execution
        Remember to use -l or --limit to run playbook on specific hosts/groups: Example: -l 'switch,router' will update RADIUS for all devices belonging to groups switch or router.
        - `ansible_user` (required): Username to log in to devices
        - `ansible_password` (required): Password to log in to devices (if a device does not log into a device in enable, this same password will be tried for enable mode)
        - `enable` (optional): Enable password for higher privileges, defaults to ansible_password when not defined
        - `community` (required): the SNMP v2c community string

        **Examples**   
        Configures global settings on a single device. 
        ```bash
        ansible-playbook playbooks/config/snmp/v2c.yml -l 'sw1' -e 'ansible_user=user' -e 'ansible_password=password' -e 'community=snmpstring'
        ```

      </details>

    - 
      <details>
      <summary>v3</summary>

      ##### `v3`
        This playbook configures SNMP v3 with provided auth/priv variables. AN ACL named "anm-ms-snmp-acl-std" is created/updated and applied to only allow snmp from the IPs specified in `./vars/jumpboxes.yml`. If jumpboxes.yml does not exist, you can copy jumpboxes-sample.yml and rename to jumpboxes.yml. You can then set the IPs for the jumpboxes like so:

        ```yaml
        snmp_allowed_ips:
          - 10.10.10.10
          - 10.10.10.20
          - 10.10.10.30
        ```

        **Supported OS:**  
        * IOS
        * IOS XE

        **Variables**
        If these variables are not passed in via the -e argument, they will be prompted for during the script execution
        Remember to use -l or --limit to run playbook on specific hosts/groups: Example: -l 'switch,router' will update RADIUS for all devices belonging to groups switch or router.
        - `ansible_user` (required): Username to log in to devices
        - `ansible_password` (required): Password to log in to devices (if a device does not log into a device in enable, this same password will be tried for enable mode)
        - `enable` (optional): Enable password for higher privileges, defaults to ansible_password when not defined
        - `snmp_user` (required): the SNMP V3 Username
        - `auth_proto` (required): the SNMP V3 Authentication Protocol (md5/sha)
        - `auth_pass` (required): the SNMP V3 Authentication password
        - `priv_proto` (required): the SNMP V3 Privacy Protocol (des,aes)
        - `priv_pass` (required): the SNMP V3 Privacy password
        - `group` (required): the SNMP V3 group that the user will belong to


        **Examples**   
        Configures SNMP v3 on a single device. 
        ```bash
        ansible-playbook playbooks/config/snmp/v3.yml -l 'sw1' -e 'ansible_user=user' -e 'ansible_password=password' -e 'snmp_user=anm' -e 'auth_proto=sha' -e 'auth_pass=password' -e 'priv_proto=aes' -e 'priv_pass=password' -e 'group=ROGROUP'
        ```

      </details>

  </details>

</details>
  -------------------------------------------------

### Verify

<details>
<summary>View Verify playbooks</summary>

- 
  <details>
  <summary>cred_validation</summary>

  #### `cred_validation`

    Playbook verifies specified credentials for the splunk inventory. Used for already onboarded client devices.

    **Supported OS:**  
    * IOS 
    * IOS XE
    * IOS XR
    * NXOS
    * ASA
    * FMC/FTD
    * Palo Alto


    **Variables** 
    If these variables are not passed in via the -e argument, they will be prompted for during the script execution
    Remember to use -l or --limit to run playbook on specific hosts/groups: Example: -l 'switch,router' will update RADIUS for all devices belonging to groups switch or router.
    - `ansible_user` (required): Username to log in to devices
    - `ansible_password` (required): Password to log in to devices (if a device does not log into a device in enable, this same password will be tried for enable mode)
    - `enable` (optional): Enable password for higher privileges, defaults to ansible_password when not defined

    **Examples**  

    Validates credential supplied on all switches using inline -e (RECOMMENDED)

    ```bash 
    ansible-playbook playbooks/verify/cred_validation.yml \
      -e '{"credential_sets":[
            {"name":"set1","username":"admin","password":"pass123"},
            {"name":"set2","username":"ops","password":"Cisco123"},
            {"name":"set3","username":"readonly","password":"readonly1"}
          ]}'
    ```

    Validates credential supplied on all switches using the creds.yml (NOT RECOMMENDED)

    ```bash 
    ansible-playbook playbooks/verify/cred_validation.yml -e @/vars/creds.yml

    ```

    **Example CLI Output**  

    ```bash
    PLAY [Validate credentials] ************************************************************

    TASK [Validate credential set 1 on R1] ************************************************
    ok: [R1] => {
        "msg": "Credential set #1 (admin) SUCCESS"
    }

    TASK [Validate credential set 2 on R1] ************************************************
    failed: [R1] => {
        "msg": "Credential set #2 (netops) FAILED"
    }

    TASK [Validate credential set 1 on R2] ************************************************
    failed: [R2] => {
        "msg": "Credential set #1 (admin) FAILED"
    }

    TASK [Validate credential set 2 on R2] ************************************************
    ok: [R2] => {
        "msg": "Credential set #2 (netops) SUCCESS"
    }

    TASK [Validate credential set 1 on FW1] ***********************************************
    failed: [FW1] => {
        "msg": "Credential set #1 (admin) FAILED"
    }

    TASK [Validate credential set 2 on FW1] ***********************************************
    ok: [FW1] => {
        "msg": "Credential set #2 (netops) SUCCESS"
    }


    TASK [Write combined results to file] *************************************************
    changed: [localhost]

    TASK [Display final results] **********************************************************
    ok: [localhost] => {
        "msg": [
            "R1: SUCCESS using credential set #1 (admin)",
            "R2: SUCCESS using credential set #2 (netops)",
            "FW1: SUCCESS using credential set #2 (netops)"
        ]
    }

    PLAY RECAP ****************************************************************************
    R1                        : ok=4    changed=0    failed=0
    R2                        : ok=4    changed=0    failed=0
    FW1                       : ok=4    changed=0    failed=0
    localhost                 : ok=2    changed=1    failed=0


    ```

  **Example File Output**
  ```yaml 

  ``` 

  </details>


- 
  <details>
  <summary>custom</summary>

  #### `custom`

    Playbook allows you to run a custom show command on a ios/ios_xe devices. Output is display on CLI as well as save in `./outputs`

    **Supported OS:**  
    * IOS 
    * IOS XE  

    **Variables** 
    If these variables are not passed in via the -e argument, they will be prompted for during the script execution
    Remember to use -l or --limit to run playbook on specific hosts/groups: Example: -l 'switch,router' will update RADIUS for all devices belonging to groups switch or router.
    - `ansible_user` (required): Username to log in to devices
    - `ansible_password` (required): Password to log in to devices (if a device does not log into a device in enable, this same password will be tried for enable mode)
    - `enable` (optional): Enable password for higher privileges, defaults to ansible_password when not defined
    - `command` (required): the show command you want to run, please use the non shortcut versions of the command, for example: show running-configuration | include dns

    **Examples**   
    Runs "show ip interface brief" on all switches 

    ```bash 
    ansible-playbook playbooks/verify/custom.yml -l 'switch' -e 'ansible_user=user' -e 'ansible_password=password' -e 'command="show ip interface brief"'
    ```

    **Example CLI Output**  

    ```bash
    TASK [Display full aggregated log file contents] ********************************************************
    ok: [R1] =>
      msg: |
        =================== Aggregated Command Output Log ===================
        =======================================================
        Device: R1
        Timestamp: 2025-11-13 18:10:45 UTC
        Command: show ip interface brief
        =======================================================
        Interface              IP-Address      OK? Method Status                Protocol
        GigabitEthernet0/0     10.1.1.1        YES manual up                    up
        GigabitEthernet0/1     unassigned      YES unset  administratively down down
        Loopback0              192.168.1.1     YES manual up                    up

        =======================================================
        Device: R2
        Timestamp: 2025-11-13 18:10:46 UTC
        Command: show ip interface brief
        =======================================================
        Interface              IP-Address      OK? Method Status                Protocol
        GigabitEthernet0/0     10.1.1.2        YES manual up                    up
        Loopback0              192.168.2.2     YES manual up                    up

    ```

  **Example File Output**
  ```yaml 
  =======================================================
  Device: R1
  Timestamp: 2025-11-13 18:10:45 UTC
  Command: show ip interface brief
  =======================================================
  Interface              IP-Address      OK? Method Status                Protocol
  GigabitEthernet0/0     10.1.1.1        YES manual up                    up
  GigabitEthernet0/1     unassigned      YES unset  administratively down down
  Loopback0              192.168.1.1     YES manual up                    up

  =======================================================
  Device: R2
  Timestamp: 2025-11-13 18:10:46 UTC
  Command: show ip interface brief
  =======================================================
  Interface              IP-Address      OK? Method Status                Protocol
  GigabitEthernet0/0     10.1.1.2        YES manual up                    up
  Loopback0              192.168.2.2     YES manual up                    up

  ``` 

  </details>

- 
  <details>
  <summary>device_discovery</summary>

  #### `device_discovery`

    This playbook performs automatic network device discovery in environments where the device OS is unknown. It attempts to connect to each host using the supported Ansible modules for IOS, IOS-XE, IOS-XR, NXOS, ASA, FMC/FTD, and Palo Alto (PAN-OS) devices.

    It gathers structured information including:
      - Hostname
      - Model
      - IOS type (if applicable)
      - Serial number
      - Stack serials (for IOS stacks)
      - Current OS version
      - Device mode (install or bundle)
      - Flash directory (if applicable)
      - Interfaces
      - Neighbors (if applicable)

    **Supported OS:**  
    * IOS 
    * IOS XE
    * IOS XR
    * NXOS
    * ASA
    * FMC/FTD
    * Palo Alto


    **Variables** 
    Make sure to pass in the inventory file with the devices to be discovered
    - `ansible_user` (required): Username to log in to devices
    - `ansible_password` (required): Password to log in to devices (if a device does not log into a device in enable, this same password will be tried for enable mode)
    - `enable` (optional): Enable password for higher privileges, defaults to ansible_password when not defined

    **Examples**  

    Device discovery with a simple inventory.

    ```bash 
    ansible-playbook playbooks/verify/cred_validation.yml -i '/vars/inventory.yml'

    ```

    **Example CLI Output**  

    ```bash
    TASK [Display discovered info per device] ************************************
    ok: [R1] => {
        "msg": {
            "hostname": "R1",
            "model": "ISR4331/K9",
            "ios_type": "XE",
            "serial": "FTX12345678",
            "stack_serials": [
                "FTX12345678",
                "FTX87654321"
            ],
            "current_ver": "17.6.3",
            "device_mode": "install",
            "flash_dir": "flash:",
            "neighbors": {
                "GigabitEthernet0/0": {
                    "neighbor": "SW1"
                }
            },
            "interfaces": {
                "GigabitEthernet0/0": {
                    "ip": "10.10.10.1/24",
                    "status": "up"
                },
                "GigabitEthernet0/1": {
                    "ip": "10.10.20.1/24",
                    "status": "down"
                }
            }
        }
    }

    ok: [SW1] => {
        "msg": {
            "hostname": "SW1",
            "model": "Nexus9000 C9396PX",
            "ios_type": "NX-OS",
            "serial": "N9K12345678",
            "stack_serials": [],
            "current_ver": "9.3(5)",
            "device_mode": "bundle",
            "flash_dir": "bootflash:",
            "neighbors": {
                "Ethernet1/1": {
                    "neighbor": "R1"
                }
            },
            "interfaces": {
                "Ethernet1/1": {
                    "ip": "10.10.10.2/24",
                    "status": "up"
                }
            }
        }
    }

    ok: [ASA1] => {
        "msg": {
            "hostname": "ASA1",
            "model": "ASA5506-K9",
            "ios_type": "",
            "serial": "JAD12345678",
            "stack_serials": [],
            "current_ver": "9.12(4)",
            "device_mode": "install",
            "flash_dir": "disk0:",
            "neighbors": {},
            "interfaces": {
                "GigabitEthernet0/0": {
                    "ip": "192.168.1.1/24",
                    "status": "up"
                }
            }
        }
    }

    ok: [PA1] => {
        "msg": {
            "hostname": "PA1",
            "model": "PA-5220",
            "ios_type": "",
            "serial": "007123456",
            "stack_serials": [],
            "current_ver": "10.1.2",
            "device_mode": "",
            "flash_dir": "",
            "neighbors": {},
            "interfaces": {
                "ethernet1/1": {
                    "ip": "10.1.1.1/24",
                    "status": "up"
                }
            }
        }
    }

    ```

  </details>

- 
  <details>
  <summary>verify_clock</summary>

  #### `verify_clock`

    This playbook verifies the current date and time on devices and compares it with the VASAs/PASAs local system time. It also collects information about configured NTP servers and NTP associations to ensure proper time synchronization. Output is displayed on CLI as well as saved in `./outputs`

    **Supported OS:**  
    * IOS 
    * IOS XE  

    **Variables** 
    If these variables are not passed in via the -e argument, they will be prompted for during the script execution
    Remember to use -l or --limit to run playbook on specific hosts/groups: Example: -l 'switch,router' will update RADIUS for all devices belonging to groups switch or router.
    - `ansible_user` (required): Username to log in to devices
    - `ansible_password` (required): Password to log in to devices (if a device does not log into a device in enable, this same password will be tried for enable mode)
    - `enable` (optional): Enable password for higher privileges, defaults to ansible_password when not defined

    **Examples**   
    Runs time verification on all switches 

    ```bash 
    ansible-playbook playbooks/verify/verify_clock.yml -l 'switch' -e 'ansible_user=user' -e 'ansible_password=password'
    ```

    **Example CLI Output**  

    ```bash
    TASK [Display time and NTP information] ******************************************************************
    ok: [R1] => 
      msg: |
        Device: R1

        === Local (WSL) Time ===
        2025-11-13 10:21:34 PST

        === Device Time ===
        *10:21:31.123 PST Thu Nov 13 2025

        === Time Verification ===
        Please compare the above times manually — adjust clock or NTP if out of sync.

        === NTP Configuration ===
        Command: show run | include ntp
        ntp server 192.168.10.1
        ntp server 192.168.10.2 prefer

        Command: show ntp associations
        address         ref clock     st  when  poll reach  delay  offset  disp
        *192.168.10.1   .GPS.          1   37    64   377   1.2    0.1     0.8
        +192.168.10.2   .GPS.          1   59    64   377   1.3    0.2     0.7
    ```

  **Example File Output**
  ```yaml
  =======================================================
  Device: R1
  Local Time: 2025-11-13 10:21:34 PST
  Device Time: 10:21:31.123 PST Thu Nov 13 2025
  =======================================================
  NTP Servers:
  ntp server 192.168.10.1
  ntp server 192.168.10.2 prefer
  NTP Associations:
  *192.168.10.1 reach=377 offset=0.1 delay=1.2
  +192.168.10.2 reach=377 offset=0.2 delay=1.3
  ``` 

  </details>

- 
  <details>
  <summary>verify_dns</summary>

  #### `verify_dns`

    This playbook collects configured DNS server information. It verifies that DNS settings are correctly configured across all devices. Output is displayed on CLI as well as saved in `./outputs`

    **Supported OS:**  
    * IOS 
    * IOS XE
    * IOS XR
    * ASA
    * FMC/FTD
    * Palo Alto

    **Variables** 
    If these variables are not passed in via the -e argument, they will be prompted for during the script execution
    Remember to use -l or --limit to run playbook on specific hosts/groups: Example: -l 'switch,router' will update RADIUS for all devices belonging to groups switch or router.
    - `ansible_user` (required): Username to log in to devices
    - `ansible_password` (required): Password to log in to devices (if a device does not log into a device in enable, this same password will be tried for enable mode)
    - `enable` (optional): Enable password for higher privileges, defaults to ansible_password when not defined

    **Examples**   
    Checks DNS servers on all switches

    ```bash 
    ansible-playbook playbooks/verify/verify_dns.yml -l 'switch' -e 'ansible_user=user' -e 'ansible_password=password'
    ```

    **Example CLI Output**  

    ```bash
    TASK [Print saved DNS log contents] ********************************************************************
    ok: [R1] =>
      msg: |
        =================== Aggregated DNS Log ===================
        =======================================================
        Device: R1
        Timestamp: 2025-11-13 20:15:12 UTC
        =======================================================
        DNS Servers:
        8.8.8.8
        8.8.4.4

        =======================================================
        Device: ASA1
        Timestamp: 2025-11-13 20:15:13 UTC
        =======================================================
        DNS Servers:
        10.10.10.10
        10.10.20.20

    ```

  **Example File Output**
  ```yaml
  =======================================================
  Device: R1
  Timestamp: 2025-11-13 20:15:12 UTC
  =======================================================
  DNS Servers:
  8.8.8.8
  8.8.4.4

  =======================================================
  Device: ASA1
  Timestamp: 2025-11-13 20:15:13 UTC
  =======================================================
  DNS Servers:
  10.10.10.10
  10.10.20.20

  ``` 

  </details>

- 
  <details>
  <summary>verify_license</summary>

  #### `verify_license`

    This playbook collects license and throughput information from devices. It checks installed licenses, their status, and hardware throughput to verify device capabilities and compliance. Output is displayed on CLI as well as saved in `./outputs`

    **Supported OS:**  
    * IOS 
    * IOS XE  

    **Variables** 
    If these variables are not passed in via the -e argument, they will be prompted for during the script execution
    Remember to use -l or --limit to run playbook on specific hosts/groups: Example: -l 'switch,router' will update RADIUS for all devices belonging to groups switch or router.
    - `ansible_user` (required): Username to log in to devices
    - `ansible_password` (required): Password to log in to devices (if a device does not log into a device in enable, this same password will be tried for enable mode)
    - `enable` (optional): Enable password for higher privileges, defaults to ansible_password when not defined

    **Examples**   
    Check license info on all switches 

    ```bash 
    ansible-playbook playbooks/verify/verify_license.yml -l 'switch' -e 'ansible_user=user' -e 'ansible_password=password'
    ```

    **Example CLI Output**  

    ```bash
    TASK [Display collected information] ********************************************************************
    ok: [R2] =>
      msg: |
        Device: R2

        === Throughput Info ===
        Command: show platform hardware throughput crypto
        Throughput: 300 Mbps

        Command: show platform hardware throughput level
        Level: 500 Mbps

        === License Info ===
        Command: show license status
        License UDI: PID:C9300-24P-E,SN:FCW2123L0AB
        Smart Licensing: ENABLED

        Command: show license all
        License Information:
          Feature: Network Advantage
          State: Active, In Use
          License Type: Permanent

        Command: show license udi
        Device# UDI:
          PID: C9300-24P-E
          SN: FCW2123L0AB

    ```

  **Example File Output**
  ```yaml
  =======================================================
  Device: R2
  Timestamp: 2025-11-13 18:05:14 UTC
  =======================================================

  === Throughput Info ===
  show platform hardware throughput crypto
  Throughput: 300 Mbps

  show platform hardware throughput level
  Level: 500 Mbps

  === License Info ===
  show license status
  Smart Licensing: ENABLED

  show license all
  Feature: Network Advantage
  State: Active, In Use
  License Type: Permanent

  show license udi
  PID: C9300-24P-E
  SN: FCW2123L0AB

  ``` 

  </details>

- 
  <details>
  <summary>verify_spanning_tree</summary>

  #### `verify_spanning_tree`

    This playbook collects and verifies Spanning Tree Protocol (STP) information from IOS/IOS-XE devices. It gathers summary, VLAN-specific, and interface-level STP details to ensure proper loop prevention, correct root bridge placement, and expected port roles. Output is displayed on CLI as well as saved in `./outputs`

    **Supported OS:**  
    * IOS 
    * IOS XE  

    **Variables** 
    If these variables are not passed in via the -e argument, they will be prompted for during the script execution
    Remember to use -l or --limit to run playbook on specific hosts/groups: Example: -l 'switch,router' will update RADIUS for all devices belonging to groups switch or router.
    - `ansible_user` (required): Username to log in to devices
    - `ansible_password` (required): Password to log in to devices (if a device does not log into a device in enable, this same password will be tried for enable mode)
    - `enable` (optional): Enable password for higher privileges, defaults to ansible_password when not defined
    - `vlan` (optional): Limit vlans, can use lists/ranges (i.e 1,10,15 or 1-10)

    **Examples**   
    Check spanning tree info on all switches for vlan 1

    ```bash 
    ansible-playbook playbooks/verify/verify_spanning_tree.yml -l 'switch' -e 'ansible_user=user' -e 'ansible_password=password' -e 'vlan=1'
    ```

    **Example CLI Output**  

    ```bash
    TASK [Print saved STP log contents] ********************************************************************
    ok: [R1] =>
      msg: |
        =================== Aggregated STP Log ===================
        =======================================================
        Device: R1
        Timestamp: 2025-11-13 18:30:12 UTC
        =======================================================

        === STP Summary ===
        VLAN0001
          Spanning tree enabled protocol ieee
          Root ID    Priority    32769
                    Address     001a.2bff.3c4d
          Hello Time 2 sec  Max Age 20 sec  Forward Delay 15 sec
          Interface              Role Sts Cost      Prio.Nbr Type
          Gi0/1                  Desg FWD 4         128.1   P2p

        === STP VLAN Info ===
        VLAN0001
          Root ID    Priority    32769
                    Address     001a.2bff.3c4d
          Bridge ID Priority 32769 (priority 32768 sys-id-ext 1)
                    Address 001a.2bff.3c4d

        === STP Interfaces ===
        Interface              Role Sts Cost      Prio.Nbr Type
        Gi0/1                  Desg FWD 4         128.1   P2p
        Gi0/2                  Root FWD 4         128.2   P2p
        Gi0/3                  Altn BLK 4         128.3   P2p

        =======================================================
        Device: R2
        Timestamp: 2025-11-13 18:30:13 UTC
        =======================================================

        === STP Summary ===
        VLAN0001
          Spanning tree enabled protocol ieee
          Root ID    Priority    32769
                    Address     001a.2bff.3c5e
          Hello Time 2 sec  Max Age 20 sec  Forward Delay 15 sec
          Interface              Role Sts Cost      Prio.Nbr Type
          Gi0/1                  Desg FWD 4         128.1   P2p

        === STP VLAN Info ===
        VLAN0001
          Root ID    Priority    32769
                    Address     001a.2bff.3c5e
          Bridge ID Priority 32769 (priority 32768 sys-id-ext 1)
                    Address 001a.2bff.3c5e

        === STP Interfaces ===
        Interface              Role Sts Cost      Prio.Nbr Type
        Gi0/1                  Desg FWD 4         128.1   P2p
        Gi0/2                  Root FWD 4         128.2   P2p
        Gi0/3                  Altn BLK 4         128.3   P2p
    ```

  **Example File Output**
  ```yaml
  =======================================================
  Device: R1
  Timestamp: 2025-11-13 18:30:12 UTC
  =======================================================

  === STP Summary ===
  VLAN0001
    Spanning tree enabled protocol ieee
    Root ID    Priority    32769
              Address     001a.2bff.3c4d
    Hello Time 2 sec  Max Age 20 sec  Forward Delay 15 sec
    Interface              Role Sts Cost      Prio.Nbr Type
    Gi0/1                  Desg FWD 4         128.1   P2p

  === STP VLAN Info ===
  VLAN0001
    Root ID    Priority    32769
              Address     001a.2bff.3c4d
    Bridge ID Priority 32769 (priority 32768 sys-id-ext 1)
              Address 001a.2bff.3c4d

  === STP Interfaces ===
  Interface              Role Sts Cost      Prio.Nbr Type
  Gi0/1                  Desg FWD 4         128.1   P2p
  Gi0/2                  Root FWD 4         128.2   P2p
  Gi0/3                  Altn BLK 4         128.3   P2p

  ```

  </details>

- 
  <details>
  <summary>verify_vlans</summary>

  #### `verify_vlans`

    This playbook collects VLAN configuration and status information from IOS/IOS-XE devices. Playbook verifies VLAN assignments, trunk interfaces, vtp info, and overall VLAN health across multiple switches. Output is displayed on CLI as well as saved in `./outputs`

    **Supported OS:**  
    * IOS 
    * IOS XE  

    **Variables** 
    If these variables are not passed in via the -e argument, they will be prompted for during the script execution
    Remember to use -l or --limit to run playbook on specific hosts/groups: Example: -l 'switch,router' will update RADIUS for all devices belonging to groups switch or router.
    - `ansible_user` (required): Username to log in to devices
    - `ansible_password` (required): Password to log in to devices (if a device does not log into a device in enable, this same password will be tried for enable mode)
    - `enable` (optional): Enable password for higher privileges, defaults to ansible_password when not defined

    **Examples**   
    Check vlan info on switches

    ```bash 
    ansible-playbook playbooks/verify/verify_vlans.yml -l 'switch' -e 'ansible_user=user' -e 'ansible_password=password'
    ```

    **Example CLI Output**  

    ```bash
    TASK [Print saved VLAN and VTP log contents] **********************************************
    ok: [R1] =>
      msg: |
        =================== Aggregated VLAN & VTP Log ===================
        =======================================================
        Device: R1
        Timestamp: 2025-11-13 19:25:12 UTC
        =======================================================

        === VLAN Brief ===
        VLAN Name                             Status    Ports
        1    default                          active    Gi0/1, Gi0/2
        10   SALES                            active    Gi0/3
        20   ENGINEERING                       active    Gi0/4

        === VLAN Summary ===
        Total VLANs configured: 3
        Active VLANs: 3
        Suspended VLANs: 0

        === VLAN Trunk Interfaces ===
        Port        Mode         Encapsulation  Status        Native VLAN
        Gi0/1       on           802.1q         trunking      1
        Gi0/2       on           802.1q         trunking      1

        === VTP Status ===
        VTP Version                     : 2
        Configuration Revision          : 42
        Maximum VLANs supported locally : 1005
        Number of existing VLANs        : 3
        VTP Operating Mode               : Server
        VTP Domain Name                  : CORP_NET
        VTP Pruning Mode                 : Disabled
        VTP V2 Mode                      : Enabled
        VTP Traps Generation             : Disabled

    ```

  **Example File Output**
  ```yaml
  =======================================================
  Device: R1
  Timestamp: 2025-11-13 19:25:12 UTC
  =======================================================

  === VLAN Brief ===
  VLAN Name                             Status    Ports
  1    default                          active    Gi0/1, Gi0/2
  10   SALES                            active    Gi0/3
  20   ENGINEERING                       active    Gi0/4

  === VLAN Summary ===
  Total VLANs configured: 3
  Active VLANs: 3
  Suspended VLANs: 0

  === VLAN Trunk Interfaces ===
  Port        Mode         Encapsulation  Status        Native VLAN
  Gi0/1       on           802.1q         trunking      1
  Gi0/2       on           802.1q         trunking      1

  === VTP Status ===
  VTP Version                     : 2
  Configuration Revision          : 42
  Maximum VLANs supported locally : 1005
  Number of existing VLANs        : 3
  VTP Operating Mode               : Server
  VTP Domain Name                  : CORP_NET
  VTP Pruning Mode                 : Disabled
  VTP V2 Mode                      : Enabled
  VTP Traps Generation             : Disabled

  ```

  </details>

</details>
-------------------------------------------------


## Scripts

<details>
<summary>iis.ps1</summary>
  
### iis.ps1
This is a powershell script that will install an http server using iis. The script will create an http folder in teh desktop. Images can be placed on this folder and can be access using: http://1.1.1.1/http/file.bin

**1. Start an elevated powershell terminal**  
* You can use windows search to search for "Powershell" then right click and select "Run as Administrator"  

**2. Run Script**   
* You can run the script by running the following:
```bash
\\wsl$\Ubuntu-18.04\opt\ansible_local\anm_itops_playbooks\scripts\iis.ps1
```
* The script may ask you for reboot if necessary, you can type yes to proceed wth reboot or decline and reboot at a later time. 
* The script may also ask for creds if IIS cannot access the new http folder, use the same creds used to log into the VASA/PASA.

**3. Verify:**  
* You may need reboot after running the script once and you see errors when running the script. After reboot, rerun the script again.
* You can verify this is working by going to a web browser and typing the following: `localhost/http`. If successful, you will get a webpage listing the contents of the http folder on teh desktop
</details>
-------------------------------------------------

<details>
<summary>excel_to_mputty_xml.py</summary>
  
### excel_to_mputty_xml.py
This is python script that can use the inventory.xlsx to create an importable mputty xml file to update mputty devices

**1. Run Script:**  
* Open WSL and navigate to `/opt/ansible_local/anm_itops_playbooks/scripts/`
* Run the following: `./scripts/excel_to_mputty_xml.py`

**2. import xml file:**   
* The script will place the file in `/opt/ansible_local/anm_itops_playbooks/scripts/outputs/mputty_inventory.xml`
* Use windows explorer to move the file to the Desktop
* Open up mputty and select File > Import
* Select the xml file obtained

**3. Verify:**  
* After successful import, verify that devices show up on mputty and that you can double-click a device to connect
</details>
-------------------------------------------------

## Procedures:
<details>
<summary>Upgrades</summary>
  
### Upgrades
**1. Determine Platform Series:** First determine what platform series are available, this list will be used to download the images from Cisco
* Run the [`get_platform_series`](#get_platform_series) playbook for example: (Review section for this playbook for further options or more details)
```bash
ansible-playbook playbooks/upgrades/get_platform_series.yml  -l 'switch,router'
```
* The last task will show you a list of device platforms based on the inventory selected, for example:

```bash
TASK [Show platform series for selected hosts/groups] ******************************************************************
ok: [ABQ-CORE-01] =>
  msg: |-
    Platform series in use:
    - c2960cx
    - c2960x
    - c3560cx
    - c9000
    - isr4300
```

**2. Download Software and Update images.yml:** Go to Cisco download page and download software for each of the displayed platforms.
NOTE: Make sure that you download .tar files for any IOS device to ensure that archive download-sw can be used:
- 2960 devices
- 3560 devices
- 3750 devices
   * Open up images.yml in Visual Studio (`/opt/ansible_local/anm_itops_playbooks/upgrades/vars`).
       * NOTE: If images.yml does not exist, make a copy of images-sample.yml within the same folder and rename to images.yml
   * Make sure to grab the following information while in the download page for the software and fill out the appropriate device platform in images.yml. MD5 and Image size can be obtained by hovering over the image name.
    - Image Name
    - Image MD5
    - Image Size in Bytes
    - Image Code - The version number of the image, IOS XE is usually in this format: xx.xx.xx so 17.09.08 for example. IOS usually has a format of xx.x(x)Ex, you can see IOS code in correct format on the release notes section of the download page.
  
   * Example info filled in for 2960x in images.yml

    ```yaml
    ##2960x 2960xr
    c2960x_target_image: c2960x-universalk9-mz.152-7.E13.tar
    c2960x_md5_hash: 03a1a35666ef516b35e487c31db8e9f9
    c2960x_image_size_bytes: 26796032
    c2960x_image_code: 15.2(7)E13
    ```
  * Save images.yml after all platform series info has been filled out
  * Move the downloaded images to the http folder on the desktop (if http folder is missing, refer to HTTP server set up guide to set up HTTP server on jumpbox)

 **3. Disk Clean Up (Optional):**
 * Run [`disk_clean_up`](#disk_clean_up) playbook to run through devices and clean up old images to prepare for new image, for example:  (Review section for this playbook for further options or more details)
```
ansible-playbook playbooks/upgrades/disk_clean_up.yml  -l 'switch,router' -e 'ansible_user=user' -e 'ansible_password=password' -e 'confirm=yes' 
```
 * If any devices fail, you may need to manually clean them up

**4. Image Upload:**
* Run the [`prestage-ios_iosxe`](#prestage-ios_iosxe) playbook, for example:  (Review section for this playbook for further options or more details)
```
ansible-playbook playbooks/upgrades/prestage-ios_iosxe.yml -l 'switch,router' -e 'ansible_user=user' -e 'ansible_password=password' -e 'http_server=172.22.15.110'
```
* If any devices fail, review the failures and fix issues (such as cleaning disk space or fixing http client source interface), refer to the troubleshooting section for this playbook for further tips.
* After troubleshooting failed devices, you can run playbook again on the failed devices directly, for example:
```
ansible-playbook playbooks/upgrades/prestage-ios_iosxe.yml -l 'sw1,rtr02' -e 'ansible_user=user' -e 'ansible_password=password' -e 'http_server=172.22.15.110'
```
* If devices continue to fail, you will need to manually prestage those devices
</details>
-------------------------------------------------
<details>
<summary>Configure AAA TACACS</summary>
  
### Configure AAA TACACS
**1. Update aaa-servers.yml:** Navigate to `/opt/ansible_local/anm_itops_playbooks/playbooks/config/aaa/vars/aaa-servers.yml`
* If aaa-servers.yml is not in the folder, you can copy aaa-servers-sample.yml, and rename it to aaa-server.yml. Open the file in Visual Studio
* Fill in the info for the TACACS servers under the `tacacs_servers` block. The only required information to fill out is name: and address:
* multiple servers can be added by copying from -name and pasting under port:, for example:
```yaml
tacacs_servers:
  - name: server1
    address: 4.4.4.4
    key: "{{ tacacs_key }}"
    port: 49
  - name: server2
    address: 5.5.5.5
    key: "{{ tacacs_key }}"
    port: 49
```
* The above will be used to configure 2 servers on devices, any servers that are not in this list will be removed from the device. 

**2. Run TACACS playbook:**   
* Run [`tacacs`](#tacacs) playbook to run through devices and configure the specified tacacs servers, for example:  (Review section for this playbook for further options or more details)
```
ansible-playbook playbooks/config/aaa/tacacs.yml -l 'switch' -e 'organization_prefix=ANM' -e 'ansible_user=user' -e 'ansible_password=password' -e 'tacacs_key=tacacs123'
```
 * Be aware that this playbook is meant to be a sort of source of truth. The script will always ensure that **ONLY** the servers in the aaa-servers list are configured.

**To remove servers:**   
* Servers can be removed by updating `/opt/ansible_local/anm_itops_playbooks/playbooks/config/aaa/vars/aaa-servers.yml` then rerunning the playbook
```
ansible-playbook playbooks/config/aaa/tacacs.yml -l 'switch' -e 'organization_prefix=ANM' -e 'ansible_user=user' -e 'ansible_password=password' -e 'tacacs_key=tacacs123'
```
</details>
-------------------------------------------------
<details>
<summary>Configure AAA RADIUS</summary>
  
### Configure AAA RADIUS
**1. Update aaa-servers.yml:** Navigate to `/opt/ansible_local/anm_itops_playbooks/playbooks/config/aaa/vars/aaa-servers.yml`
* If aaa-servers.yml is not in the folder, you can copy aaa-servers-sample.yml, and rename it to aaa-server.yml. Open the file in Visual Studio
* Fill in the info for the TACACS servers under the `radius_servers` block. The only required information to fill out is name: and address:
* multiple servers can be added by copying from -name and pasting under port:, for example:
```yaml
radius_servers:
  - name: server1
    address: 4.4.4.4
    key: "{{ radius_key }}"
    auth_port: 1812
    acct_port: 1813
  - name: server2
    address: 5.5.5.5
    key: "{{ radius_key }}"
    auth_port: 1812
    acct_port: 1813
```
* The above will be used to configure 2 servers on devices, any servers that are not in this list will be removed from the device. 

**2. Run RADIUS playbook:**   
* Run [`radius`](#radius) playbook to run through devices and configure the specified tacacs servers, for example:  (Review section for this playbook for further options or more details)
```
ansible-playbook playbooks/config/aaa/radius.yml -l 'switch' -e 'organization_prefix=ANM' -e 'ansible_user=user' -e 'ansible_password=password' -e 'radius_key=tacacs123'
```
 * Be aware that this playbook is meant to be a sort of source of truth. The script will always ensure that **ONLY** the servers in the aaa-servers list are configured.

**To remove servers:**   
* Servers can be removed by updating `/opt/ansible_local/anm_itops_playbooks/playbooks/config/aaa/vars/aaa-servers.yml` then rerunning the playbook
```
ansible-playbook playbooks/config/aaa/radius.yml -l 'switch' -e 'organization_prefix=ANM' -e 'ansible_user=user' -e 'ansible_password=password' -e 'radius_key=tacacs123'
```
</details>
-------------------------------------------------
<details>
<summary>Onboarding</summary>
  
### Onboarding

**1. Create inventory file:** Navigate to `/opt/ansible_local/anm_itops_playbooks/playbooks/verify/vars`
* Duplicate file named onboard-sample.yml and rename to onboard.yml
* Follow the format in the sample to fill out the hostnames and IPs
* multiple devices can be added by copying from R1 and pasting under ansible_host, for example:

```yaml
all:
  hosts:
    R1:
      ansible_host: 10.10.1.1
    SW1:
      ansible_host: 10.10.1.2
    ASA1:
      ansible_host: 10.10.1.3
    FTD1:
      ansible_host: 10.10.1.4
    PA1:
      ansible_host: 10.10.1.5
```

**2. Run device_discovery playbook:**   
* Run [`device_discovery`] playbook to run through devices and obtain information, use -i to pass the newly created onboard.yml inventory file, for example:  (Review section for this playbook for further options or more details)

```bash
ansible-playbook playbooks/verify/device_discovery.yml -i '/opt/ansible_local/anm_itops_playbooks/playbooks/verify/vars/onboard.yml' -e 'ansible_user=user' -e 'ansible_password=password'
```

**3. Configure SNMP using v2c or v3**  (Review section for this playbook for further options or more details)

</details>
-------------------------------------------------
