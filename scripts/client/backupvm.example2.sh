#!/bin/bash

set -o pipefail

export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

VMID=$1
SSH_USER="backupuser"
SSH_IP="serverip"
SSH_PORT="serverport"
LOCAL_BACKUP_PATH="local backup path"
TMP_FILE="backupvm.tmp"

if [ -z "$VMID" ]
then
        echo "VMID is empty"
        exit 1
fi

if [ -f "${LOCAL_BACKUP_PATH}/${TMP_FILE}" ]; then
        echo "Temporary backup file exist"
        exit 1
fi

LOCAL_FILE_TO_BACKUP=$(ls -t ${LOCAL_BACKUP_PATH}/vzdump-qemu-"${VMID}"*zst | head -2 | tail -1)

if [ ! -f "$LOCAL_FILE_TO_BACKUP" ]; then
    echo "$LOCAL_FILE_TO_BACKUP does not exist."
    exit 1
fi

if [ "$(( ($(date +%s) - $(stat -L --format %Y "$LOCAL_FILE_TO_BACKUP")) > (30*24*3600) ))" -ne "0" ]; then
   echo "Warning file older than 30 days";
fi


ln "$LOCAL_FILE_TO_BACKUP" "${LOCAL_BACKUP_PATH}/${TMP_FILE}"

DATEBCK=$(date +"%d-%m-%Y-%H:%M")
BACKUP_NAME="${VMID}_${DATEBCK}"


echo "ssh $SSH_USER@$SSH_IP -p $SSH_PORT 'echo ok' && zstd -d ${LOCAL_BACKUP_PATH}/${TMP_FILE} --stdout | /usr/bin/borg create --stdin-name $BACKUP_NAME.vma --compression=lz4 --stats ssh://$SSH_USER@$SSH_IP:$SSH_PORT/home/$SSH_USER/backupproxmox::$BACKUP_NAME - 2>&1"
BORG_CREATE_RESULT=$(ssh $SSH_USER@$SSH_IP -p $SSH_PORT "echo ok" && zstd -d "${LOCAL_BACKUP_PATH}/${TMP_FILE}" --stdout | /usr/bin/borg create --stdin-name "$BACKUP_NAME.vma" --compression=lz4 --stats "ssh://$SSH_USER@$SSH_IP:$SSH_PORT/home/$SSH_USER/backupproxmox::$BACKUP_NAME" - 2>&1)

BORG_CREATE_RET="$?"

rm "${LOCAL_BACKUP_PATH}/${TMP_FILE}"

echo "borg prune -v --list --keep-last=3 --keep-monthly=2 ssh://$SSH_USER@$SSH_IP:$SSH_PORT/home/$SSH_USER/backupproxmox --prefix=${VMID}_ 2>&1"
BORG_PRUNE_RESULT=$(borg prune -v --list --keep-last=3 --keep-monthly=2 "ssh://$SSH_USER@$SSH_IP:$SSH_PORT/home/$SSH_USER/backupproxmox" --prefix="${VMID}_" 2>&1 )
BORG_PRUNE_RET="$?"

echo "borg compact --cleanup-commits ssh://$SSH_USER@$SSH_IP:$SSH_PORT/home/$SSH_USER/backupproxmox 2>&1"
BORG_COMPACT_RESULT=$(borg compact --cleanup-commits "ssh://$SSH_USER@$SSH_IP:$SSH_PORT/home/$SSH_USER/backupproxmox" 2>&1 )
BORG_COMPACT_RET="$?"



read -r -d '' ZABBIX_RESULT << EOM
BORG CREATE code : ${BORG_CREATE_RET} 
Log :
${BORG_CREATE_RESULT}

BORG PRUNE code : ${BORG_PRUNE_RET}
Log :
${BORG_PRUNE_RESULT}

BORG COMPACT code : ${BORG_COMPACT_RET}
Log :
${BORG_COMPACT_RESULT}

EOM

echo "/bin/zabbix_sender -c /etc/zabbix/zabbix_agentd.conf -k borg.backup.vmbackup[$VMID] -o $ZABBIX_RESULT"
/usr/bin/zabbix_sender -c /etc/zabbix/zabbix_agentd.conf -k "borg.backup.vmbackup[$VMID]" -o "$ZABBIX_RESULT"

