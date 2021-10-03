#!/bin/sh
PATH=/bin:/usr/bin:/sbin:/usr/sbin

#
# Script for turning on EDUTM mode
#

if /usr/bin/hciconfig | /bin/grep hci; then
	echo EDUTM already done, exit
else
	echo Start EDUTM
	/usr/etc/bluetooth/bt-edutm-dev-up.sh
fi

if [ -e /usr/etc/bluetooth/TIInit_* ]
then
	echo "Reset device"
	/usr/bin/hcitool cmd 0x3 0xFD0C
fi

echo "Configure BT device"
/usr/bin/hcitool cmd 0x3 0x0005 0x02 0x00 0x02

echo "Send BT edutm command"
/usr/bin/hcitool cmd 0x06 0x0003

echo "BT edutm done"
