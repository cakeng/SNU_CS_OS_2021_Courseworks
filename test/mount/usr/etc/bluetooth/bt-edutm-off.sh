#!/bin/sh
PATH=/bin:/usr/bin:/sbin:/usr/sbin

#
# Script for turning off Bluetooth(EDUTM)
#

# Kill BlueZ bluetooth stack
/usr/bin/killall bluetoothd

# Remove BT device
/usr/etc/bluetooth/bt-dev-end.sh

# result
exit 0
