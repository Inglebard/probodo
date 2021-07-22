#based on https://github.com/ganehag/pve-vma-docker
FROM debian:bullseye

WORKDIR /tmp

RUN apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y wget zstd libglib2.0-0 libiscsi7 librbd1 libaio1 lzop glusterfs-common libcurl4-gnutls-dev liburing-dev ssh borgbackup  && \
  echo "deb http://download.proxmox.com/debian/pve bullseye pve-no-subscription" >> /etc/apt/sources.list && \
  wget http://download.proxmox.com/debian/proxmox-release-bullseye.gpg    -O /etc/apt/trusted.gpg.d/proxmox-release-bullseye.gpg && \
  chmod +r /etc/apt/trusted.gpg.d/proxmox-release-bullseye.gpg && \
  apt-get update && \
  apt-get install -y libproxmox-backup-qemu0-dev && \
  apt-get download pve-qemu-kvm && \
  dpkg --fsys-tarfile ./pve-qemu-kvm*.deb | tar xOf - ./usr/bin/vma > ./vma && \
  chmod u+x ./vma && \
  mv ./vma /usr/local/bin && \
  mkdir -p /backup && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  mkdir -p /run/sshd


COPY ./entrypoint.sh /entrypoint.sh 
COPY ./config.d /config.d/
COPY ./scripts /scripts/

RUN chmod a+x /scripts/*.sh && chmod a+x /scripts/client/*.sh && chmod a+x /config.d/*.sh && chmod a+x /entrypoint.sh  && chmod a+x /usr/local/bin/vma

WORKDIR /

ENTRYPOINT /entrypoint.sh

