#!/bin/sh
PATH=/bin:/usr/bin:/sbin:/usr/sbin
PGREP=/usr/bin/pgrep

#
# Script for stopping Broadcom UART Bluetooth stack
#

# Device down
/usr/bin/hciconfig hci0 down

# OMAP4
REVISION_NUM=`grep Revision /proc/cpuinfo | awk "{print \\$3}"`
if [ $REVISION_NUM == "0006" ]; then
	rmmod bt_drv.ko
	rmmod st_drv.ko
	sleep 1
	UIM_RFKILL_PID=$($PGREP uim_rfkill)
	kill $UIM_RFKILL_PID
	exit 0
fi

#if [ -e /sys/class/gpio/gpio17/value ]
#then
#	# Reset BT chip
#	echo 0 > /sys/class/gpio/gpio17/value
#	sleep 0.1
#	echo 1 > /sys/class/gpio/gpio17/value
#fi

