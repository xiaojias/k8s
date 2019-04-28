# Ansible 

In order to help easily automating repeatitive tasks, this repository intents to provide a simple structure to execute and create playbooks or ad-hoc commands from the Jump server or from the Autobuild servers.

Be sure that your your SSH public key is part of authorized_keys of the users that will be executing the commands on the servers.

## Understanding the Inventory

Ansible works against multiple systems at the same time. It does this by selecting portions of systems listed in Ansible’s inventory, which defaults to being saved in the location `$HOME/mneaas-devops/ansible/inventory`. You can specify a different inventory file using the -i <path> option on the command line.

There are 2 inventory files, for each of the regions where the infrastructure servers are hosted (Amsterdan and Washington):

- `$HOME/mneaas-devops/ansible/inventory/ams.yaml`
- `$HOME/mneaas-devops/ansible/inventory/wdc.yaml`

Both files are defined according to the following structure:

```
all --> segment (ires/sres/dres) 
           --> environment (ispw/shared/preprod/dc1/bge) 
                   --> tool (ipm/netcool) --> 
                         --> role (ipm_proxy, webgui, etc) 
                               --> hostname
```

The intention is that one can parse the inventory by segment, environment, tool or role of the server, in order to facilitate the creation of playbooks or execution of ad-hoc commands.

**As shown in the examples below, on how to run the `whoami` command on multiple servers....**

- on all AMS servers:
`ansible -i inventory/ams.yaml all -m shell -a "whoami"`

- on all AMS DRES Probes:
`ansible -i inventory/ams.yaml dres -l "*probes*" -m shell -a "whoami"`

- on all AMS SRES Omnibus Secondary Servers:
`ansible -i inventory/ams.yaml sres -l "*omnibus_secondary*" -m shell -a "whoami"`

- on all WDC ISPW Servers:
`ansible -i inventory/wdc.yaml ispw  -m shell -a "whoami"`

### Running commands with privilege

The default setup for this set of files is to execute all commands without any privilege, however if sudo is required, you can execute commands with sudo using variables and passwords stored in a vault, as shown in the examples below:


**Running command with your personal user:**

```
fsilveira@eu1sr1ljmp01:~/mneaas-devops/ansible$ ansible -i inventory/ams.yaml ams_sres_preprod_netcool_impact_primary -m shell -a "whoami" --ask-vault-pass
Vault password: 
ams_sres_preprod_netcool_impact_primary | SUCCESS | rc=0 >>
fsilveira
```

**Running command with sudo using credentials from a vault:**

```
fsilveira@eu1sr1ljmp01:~/mneaas-devops/ansible$ ansible -i inventory/ams.yaml ams_sres_preprod_netcool_impact_primary -m shell -a "echo {{ ssh_pass }} | sudo -S whoami" --ask-vault-pass
Vault password: 
ams_sres_preprod_netcool_impact_primary | SUCCESS | rc=0 >>
root

fsilveira@eu1sr1ljmp01:~/mneaas-devops/ansible$ 
```

To setup your credentials file and encrypt it with ansible-vault, you can execute `$HOME/mneaas-devops/ansible/vault-setup.sh`, as shown below:

```
fsilveira@eu1sr1ljmp01:~/mneaas-devops/ansible$ ./vault-setup.sh 
Type your ssh user id:
fsilveir
Type your ssh user pass:
Type your ssh public key (1-line):
ssh-rsa AAAAAAAAAAAAAAABBBBBBBBBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCC_KEYCONTENT_DDDDDDDDDDDDDDEEEEEEEEEEEEEEEEEEEEEGGGGGGGGGGGGGGGGG
Type your github token:
AAAAAABBBBBBBBBBBCCCCCCCCCCDDDDDDDDDD
Type your W3/IBMID id:
fsilveir@br.ibm.com
Type your W3/IBMID password:
New Vault password: 
Confirm New Vault password: 
Encryption successful
```

The script will save your encripted credentials at `$HOME/.ansible`, which is linked by default to the inventory `group_vars` directory, so that you can safely store your credentials to use on your playbooks and ad-hoc commands.

Just be aware that when storing credentials on `ansible-vault`, you'll need to inform the vault password when executing a plabook on ad-hoc commands, or else you'll receive the following message:

```
ERROR! Decryption failed
```

To include the vault password, just add `--ask-vault-pass` after invoking the playbook or ad-hoc command.

### Understanding Group Variables

In order to facilitate and keep a common standard on playbooks, there are multiple values that are common to different environemnts that are defined as group variables. For instace application ports, or IP addresses of external servers, such as ISPW proxies. Check the following files on `$HOME/mneaas-devops/ansible/inventory/group_vars/all` for details:

| filename                    | description                                                                        |
| --------------------------- | ---------------------------------------------------------------------------------- |
| hosts.yaml                  | Servers managed by other teams, such as proxies, relays, IPCenter gateways, etc.   |
| application_ports.yaml      | Port numbers for common applications such as ssh, https, UCD, Samba ports and etc. |
| ipm_saas_subscriptions.yaml | IPM SaaS Subscription information such as subscription id, region and URL.         |


## Ad-Hoc Oneliner's


#### List all ansible modules s

`ansible-doc -l`

#### Ping ALL hosts (25 forks)
`ansible -i inventory/ams.yaml all -m ping -f 25 -o`

#### Get Tivoli EIF Log from AMS-IRES-ISPW_Netcool_Probes_Primary
`ansible -i inventory/ams.yaml ams_ires_ispw_netcool_probes_primary  -m shell -a "cat /opt/IBM/GSMA/logs/ObjectServer/tivoli_eif.log" > tivoli_eif.log`

#### Get Tivoli EIF Log from AMS-IRES-ISPW_Netcool_Probes_Secondary
`ansible -i inventory/ams.yaml ams_ires_ispw_netcool_probes_secondary  -m shell -a "cat /opt/IBM/GSMA/logs/ObjectServer/tivoli_eif.log" > tivoli_eif.log`

#### Check if 'bc' package is present on ALL hosts
`ansible all -i inventory/ams.yaml all -m yum -a "name=bc state=present"`

#### Playbook useful options

-  `-C` Dry run
-  `--step` step by step run

## Ansible Playbooks

To execute the playbooks, clone this repository to your home directory at the jump host or on the autobuild servers, and them execute the following:

```bash
$ git clone git@github.ibm.com:mne/mneaas-devops.git
$ cd mneaas-devops/ansible
$ ansible-playbook playbooks/<playbook_name> -i inventory/<inventory_file> [ -l <host_name>]
```
### Copying SSH public key in bulk

To copy a new user ssh-key to multiple servers, you can use the following as example, passing the username and ssh public key as arguments/extra variabls:

```
$ ansible-playbook -i inventory/ams.yaml playbooks/infra/ssh-key-copy.yml --extra-vars='{ pubkey : "ssh-rsa AAAAAAAAAAAAAAABBBBBBBBBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCC_KEYCONTENT_DDDDDDDDDDDDDDEEEEEEEEEEEEEEEEEEEEEGGGGGGGGGGGGGGGGG", username : "fsilveir" }'
```

#### Check Netcool Probe status

For instance:

```bash
fsilveira@eu1sr1ljmp01:~/mneaas-devops/ansible$ ansible-playbook playbooks/misc/process-probes.yaml -i inventory/ams.yaml -l "*probes*" --ask-vault-pass
Vault password: 

PLAY ***************************************************************************

TASK [Check if NCO service is running] *****************************************
ok: [ams_sres_shared_netcool_probes]
ok: [ams_dres_bge_netcool_probes_secondary]
fatal: [ams_sres_preprod_netcool_probes]: FAILED! => {"changed": false, "cmd": "systemctl status nco", "delta": "0:00:00.008517", "end": "2019-03-03 02:27:54.425526", "failed": true, "rc": 3, "start": "2019-03-03 02:27:54.417009", "stderr": "", "stdout": "● nco.service - LSB: Netcool/OMNIbus\n   Loaded: loaded (/etc/rc.d/init.d/nco; bad; vendor preset: disabled)\n   Active: inactive (dead) since Sat 2019-02-16 13:58:49 CET; 2 weeks 0 days ago\n     Docs: man:systemd-sysv-generator(8)", "stdout_lines": ["● nco.service - LSB: Netcool/OMNIbus", "   Loaded: loaded (/etc/rc.d/init.d/nco; bad; vendor preset: disabled)", "   Active: inactive (dead) since Sat 2019-02-16 13:58:49 CET; 2 weeks 0 days ago", "     Docs: man:systemd-sysv-generator(8)"], "warnings": []}
ok: [ams_dres_bge_netcool_probes_primary]
ok: [ams_ires_ispw_netcool_probes_primary]
ok: [ams_dres_dc1_netcool_probes_secondary]
ok: [ams_dres_dc1_netcool_probes_primary]

TASK [Check  EIF_PROBE processes are running] **********************************
ok: [ams_dres_bge_netcool_probes_primary]
ok: [ams_sres_shared_netcool_probes]
ok: [ams_dres_bge_netcool_probes_secondary]
ok: [ams_dres_dc1_netcool_probes_primary]
ok: [ams_ires_ispw_netcool_probes_primary]
ok: [ams_dres_dc1_netcool_probes_secondary]

TASK [Check PING PROBE processes are running] **********************************
ok: [ams_dres_bge_netcool_probes_primary]
ok: [ams_sres_shared_netcool_probes]
ok: [ams_dres_bge_netcool_probes_secondary]
ok: [ams_dres_dc1_netcool_probes_primary]
ok: [ams_ires_ispw_netcool_probes_primary]
ok: [ams_dres_dc1_netcool_probes_secondary]

TASK [Check SNMP PROBE processes are running] **********************************

ok: [ams_dres_bge_netcool_probes_secondary]
ok: [ams_dres_dc1_netcool_probes_primary]
ok: [ams_sres_shared_netcool_probes]
ok: [ams_ires_ispw_netcool_probes_primary]
ok: [ams_dres_dc1_netcool_probes_secondary]

TASK [Check MSGBUS PROBE processes are running] ********************************
ok: [ams_sres_shared_netcool_probes]
ok: [ams_dres_bge_netcool_probes_primary]
ok: [ams_dres_bge_netcool_probes_secondary]
ok: [ams_dres_dc1_netcool_probes_primary]
ok: [ams_ires_ispw_netcool_probes_primary]
ok: [ams_dres_dc1_netcool_probes_secondary]

PLAY RECAP *********************************************************************
ams_dres_bge_netcool_probes_primary : ok=5    changed=0    unreachable=0    failed=0   
ams_dres_bge_netcool_probes_secondary : ok=5    changed=0    unreachable=0    failed=0   
ams_dres_dc1_netcool_probes_primary : ok=5    changed=0    unreachable=0    failed=0   
ams_dres_dc1_netcool_probes_secondary : ok=5    changed=0    unreachable=0    failed=0   
ams_ires_ispw_netcool_probes_primary : ok=5    changed=0    unreachable=0    failed=0   
ams_sres_preprod_netcool_probes : ok=0    changed=0    unreachable=0    failed=1   
ams_sres_shared_netcool_probes : ok=5    changed=0    unreachable=0    failed=0   

fsilveira@eu1sr1ljmp01:~/mneaas-devops/ansible$ 

```

## Generating Hardware Inventory

To update the hardware inventory, use the [Ansible Configuration Management Database module](https://github.com/fboender/ansible-cmdb) to generate host overview from ansible fact gathering output.


First step is to gather the facts by executing the following:


### To gather facts from AMS servers:
```bash
 $ ansible -i inventory/ams.yaml -m setup --tree $HOME/mneaas-devops/ansible/cmdb/ all --ask-vault-pass
```

### To gather facts from WDC servers:
```bash
 $ ansible -i inventory/wdc.yaml -m setup --tree $HOME/mneaas-devops/ansible/cmdb/ all --ask-vault-pass
```

Generate the CMDB HTML with Ansible-cmdb with the following command:

```
$ ansible-cmdb $HOME/mneaas-devops/ansible/cmdb/ > $HOME/mneaas-devops/ansible/cmdb/mneaas-cmdb.html
```


## Common Problems

#### Fix /dev/null error when trying to remotely login

When someone writes a file to `/dev/null` ansible is not able to remotely execute commands, execute the following as root to fix the issue:

`rm -f /dev/null; mknod -m 666 /dev/null c 1 3`

