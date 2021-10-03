#!/bin/sh
PATH=/bin:/usr/bin:/sbin:/usr/sbin
PGREP=/usr/bin/pgrep

#
# Script for stopping Bluetooth stack
#

# Remove BT device
/usr/etc/bluetooth/bt-dev-end.sh

# Kill BlueZ bluetooth stack

pkill --full obexd
pkill --full obexd-client
pkill --full bt-syspopup
pkill --full bluetooth-pb-agent
pkill --full bluetooth-map-agent
pkill --full bluetooth-hfp-agent
pkill --full bluetoothd

# result
exit 0
