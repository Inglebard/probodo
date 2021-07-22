#!/bin/bash

set -o pipefail

BACKUP_PATH=$1
VMID=$2

if [ ! -d "$BACKUP_PATH" ] 
then
    echo "Directory ${BACKUP_PATH} exists."
	exit 1
fi


if [ -z "$VMID" ]
then
	echo "VMID is empty"
	exit 1
fi



# Get last backup 
LAST_BACKUP=$(borg list "$BACKUP_PATH" --prefix "$VMID" --last 1 --short)
BORG_LIST_RETURN="$?"

if [ -z "$LAST_BACKUP" ] || [ $BORG_LIST_RETURN -ne 0 ]
then
	echo "Backup not found"
	exit 1
fi

# Verify last backup 
ARCHIVE_FULL_PATH="${BACKUP_PATH}::${LAST_BACKUP}"

borg extract --stdout "$ARCHIVE_FULL_PATH" | vma verify -v -

exit $?

