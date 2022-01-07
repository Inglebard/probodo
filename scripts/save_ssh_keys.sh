#!/bin/bash
SSH_HOST_FILES="/etc/ssh/ssh_host_*"
for f in $SSH_HOST_FILES
do
	echo "echo | tee $f << EndOfKey"	
  	cat "$f"	
	echo "EndOfKey"
done
