#!/bin/bash


VMID=$1
SSH_USER="backupuser"
SSH_IP="serverip"
SSH_PORT="serverport"

BACKUP_PATH="/home/$SSH_USER/backupproxmox"

if [ -z "$VMID" ]
then
        echo "VMID is empty"
        exit 1
fi

echo "ssh $SSH_USER@$SSH_IP -p $SSH_PORT /scripts/checkbackupvm.sh $BACKUP_PATH $VMID"

RESULT=$(ssh "$SSH_USER@$SSH_IP" -p "$SSH_PORT" "/scripts/checkbackupvm.sh ${BACKUP_PATH} ${VMID}")
RET="$?"

read -r -d '' ZABBIX_RESULT << EOM
VM CHECK code : ${RET} 
Log :
${RESULT}

EOM

echo "/usr/bin/zabbix_sender -c /etc/zabbix/zabbix_agentd.conf -k borg.backup.vmcheck[$VMID] -o $ZABBIX_RESULT"

/usr/bin/zabbix_sender -c /etc/zabbix/zabbix_agentd.conf -k "borg.backup.vmcheck[$VMID]" -o "$ZABBIX_RESULT"
