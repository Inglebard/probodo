#!/bin/bash

#Zabbix BORG
#Value should be in json format

zabbix_sender -c /etc/zabbix/zabbix_agentd.conf -k borg.backup.discovery -o '{"data":[{"vmid":"100"}]}'

#For multiples VM, here is an example
#zabbix_sender -c /etc/zabbix/zabbix_agentd.conf -k borg.backup.discovery -o '{"data":[{"vmid":"100"},{"vmid":"101"}]}'
