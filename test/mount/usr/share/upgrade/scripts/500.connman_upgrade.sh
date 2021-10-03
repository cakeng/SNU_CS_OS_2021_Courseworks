#!/bin/sh
PATH=/bin:/usr/bin:/sbin:/usr/sbin

#------------------------------------------------------------#
# connman patch script for upgrade (3.0 -> the latest tizen) #
#------------------------------------------------------------#

chmod 755 /var/lib/connman
chown -R network_fw:network_fw /var/lib/connman
