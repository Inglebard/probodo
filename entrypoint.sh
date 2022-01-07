#!/bin/bash


sed -i \
	-e 's/^#PasswordAuthentication yes$/PasswordAuthentication no/g' \
	-e 's/^PermitRootLogin without-password$/PermitRootLogin no/g' \
	/etc/ssh/sshd_config

rm /etc/ssh/ssh_host_* && dpkg-reconfigure openssh-server

chown root:root /home
chmod 755 /home

chmod a+x /scripts/*.sh && chmod a+x /scripts/client/*.sh && chmod a+x /config.d/*.sh && chmod a+x /entrypoint.sh  && chmod a+x /usr/local/bin/vma

#https://stackoverflow.com/a/41079188/3899847
for f in /config.d/*.sh; do
  bash "$f" || break  # execute successfully or break
  # Or more explicitly: if this execution fails, then stop the `for`:
  # if ! bash "$f"; then break; fi
done

exec /usr/sbin/sshd -D -e

