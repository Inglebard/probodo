#!/bin/bash

set -o pipefail

export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

VMID=$1
SSH_USER="backupuser"
SSH_IP="serverip"
SSH_PORT="serverport"

if [ -z "$VMID" ]
then
        echo "VMID is empty"
        exit 1
fi

/usr/sbin/qm status "$VMID" > /dev/null 2>&1

if [ $? -ne 0 ]
then
        echo "VM not exist"
        exit 1
fi

DATEBCK=$(date +"%d-%m-%Y-%H:%M")
BACKUP_NAME="${VMID}_${DATEBCK}"


echo "ssh $SSH_USER@$SSH_IP -p $SSH_PORT 'echo ok' && /usr/bin/vzdump $VMID --compress 0 --mode snapshot --dumpdir /tmp --stdout --quiet | /usr/bin/borg create --stdin-name $BACKUP_NAME.vma --compression=lz4 --stats ssh://$SSH_USER@$SSH_IP:$SSH_PORT/home/$SSH_USER/backupproxmox::$BACKUP_NAME - 2>&1"
BORG_CREATE_RESULT=$(ssh $SSH_USER@$SSH_IP -p $SSH_PORT "echo ok" && /usr/bin/vzdump "$VMID" --compress 0 --mode snapshot --dumpdir /tmp --stdout --quiet | /usr/bin/borg create --stdin-name "$BACKUP_NAME.vma" --compression=lz4 --stats "ssh://$SSH_USER@$SSH_IP:$SSH_PORT/home/$SSH_USER/backupproxmox::$BACKUP_NAME" - 2>&1)

BORG_CREATE_RET="$?"


echo "borg prune -v --list --keep-last=3 --keep-monthly=2 ssh://$SSH_USER@$SSH_IP:$SSH_PORT/home/$SSH_USER/backupproxmox --prefix=${VMID}_ 2>&1"
BORG_PRUNE_RESULT=$(borg prune -v --list --keep-last=3 --keep-monthly=2 "ssh://$SSH_USER@$SSH_IP:$SSH_PORT/home/$SSH_USER/backupproxmox" --prefix="${VMID}_" 2>&1 )
BORG_PRUNE_RET="$?"



read -r -d '' ZABBIX_RESULT << EOM
BORG CREATE code : ${BORG_CREATE_RET} 
Log :
${BORG_CREATE_RESULT}

BORG PRUNE code : ${BORG_PRUNE_RET}
Log :
${BORG_PRUNE_RESULT}

EOM

echo "/bin/zabbix_sender -c /etc/zabbix/zabbix_agentd.conf -k borg.backup.vmbackup[$VMID] -o $ZABBIX_RESULT"
/usr/bin/zabbix_sender -c /etc/zabbix/zabbix_agentd.conf -k "borg.backup.vmbackup[$VMID]" -o "$ZABBIX_RESULT"
