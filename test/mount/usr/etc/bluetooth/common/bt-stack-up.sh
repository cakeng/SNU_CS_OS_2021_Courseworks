#!/bin/sh
PATH=/bin:/usr/bin:/sbin:/usr/sbin

#
# Script for executing Bluetooth stack
#

# Register BT Device
/usr/etc/bluetooth/bt-dev-start.sh

if !(/usr/bin/hciconfig | grep hci); then
	echo "Registering BT device is failed."
	exit 1
fi

exit 0
