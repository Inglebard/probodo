# ProBoDo

ProBoDo is a Docker image designed to be used as Borg Backup server. It contains also a Proxmox utility to check vma backup files consistency.

# Files

Here is a explanation of all the files present in the Docker images :

**config.d** : All the scripts present in this folder will be executed at startup.
**config.d/10-createusersandgroups.sh** : Create users defined in **users.conf**
**config.d/users.conf** : List of users created at startup. Format: UID|name

**cron_client/root_crontab.example.txt** : An example on how to use theses scripts with cron

**home** : Empty on first start. Users data will populate this directory. I recommend to do Borg backup inside user data, this will allow "home" to be a central place to have Borg backup and users ssh keys. Use home has a volume or a bind to persist data.

**scripts**: Contains all useful scripts. You may want to add your custom scripts here.
**scripts/checkbackupvm.sh**: Verify if a Proxmox backup (VMA) is valid.
**scripts/createuserandgroup.sh**: Create user and group without restart the container.

**scripts/client**: Contains example script that can be executed in the client. You may want to add your client template custom scripts here.
**scripts/client/backupvm.example.sh**: Example script to backup Proxmox VM
**scripts/client/verifybackup.example.sh**: Example script to verify a backup of Proxmox VM
**scripts/client/zabbix.example.sh**: Example script to monitor with zabbix discovery

**zabbix/zbx_export_templates.xml** : An example of Zabbix model

**entrypoint.sh** : It is the script executed on Docker container start

# How to launch the image

The image required to be accessible through SSH port and I recommend to bind the home directory to persist data.

So you just need something like this or use a docker-compose.yml file:

docker run -d  -p [your external port]:22 -v /path/to/persist/homedata/:/home --name probodo inglebard/probodo

After the users created and before create your first backup, you will need to add the ssh key to your clients in /home/[your_user]/.ssh/authorized_keys


# Based on

https://github.com/ganehag/pve-vma-docker
