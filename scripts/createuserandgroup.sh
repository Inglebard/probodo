#!/bin/bash

USER_ID=$1
USER_NAME=$2

function group_exists {
    if [ $(getent group "$1") ]; then
		echo "TRUE"
		return 0
    else
		echo "FALSE"
		return 1
    fi
}

function user_exists {
	if id "$1" &>/dev/null; then
		echo "TRUE"
		return 0
	else
		echo "FALSE"
		return 1
	fi
}



USERSCONF="/config.d/users.conf"
	
echo "ID: $USER_ID && NAME: $USER_NAME"

if [ $(group_exists "$USER_ID") == "TRUE" ]; then
	echo "Group exists";
else
	echo "Group not exists";
	groupadd -g "$USER_ID" "$USER_NAME"
fi

if [ $(user_exists "$USER_ID") == "TRUE" ]; then
	echo "User exists";
else
	echo "User not exists";

	if [ ! -d "/home/$USER_NAME/" ] 
	then
		useradd "$USER_NAME" --uid "$USER_ID" --home "/home/$USER_NAME/" --create-home --gid "$USER_NAME" -p "*" --shell /bin/bash
	else
		useradd "$USER_NAME" --uid "$USER_ID" --home "/home/$USER_NAME/" --no-create-home --gid "$USER_NAME" -p "*" --shell /bin/bash
	fi

	#if [ ! -d "/home/$USER_NAME/backupproxmox" ] 
	#then
	#	mkdir "/home/$USER_NAME/backupproxmox"
	#fi
	if [ ! -d "/home/$USER_NAME/.ssh" ] 
	then
		mkdir "/home/$USER_NAME/.ssh"
		touch "/home/$USER_NAME/.ssh/authorized_keys"
		chmod 700 "/home/$USER_NAME/.ssh"
		chmod 600 "/home/$USER_NAME/.ssh/authorized_keys"
		chown -R "$USER_NAME":"$USER_NAME" "/home/$USER_NAME/.ssh"
	fi
	echo "${USER_ID}|${USER_NAME}" >> $USERSCONF

fi
