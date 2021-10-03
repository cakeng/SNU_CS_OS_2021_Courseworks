#!/bin/sh
PATH=/bin:/usr/bin:/sbin:/usr/sbin

#
# Script for turning on Bluetooth EDUTM
#

HCIDUMP_ENABLE="true"	# Available values : true | false (default : false)
HCIDUMP_DIR="/opt/usr/media/.bt_dump"
HCIDUMP_FILENAME="bt_hcidump.log"
HCIDUMP_PATH="${HCIDUMP_DIR}/${HCIDUMP_FILENAME}"
LOGDUMP_DIR="/opt/etc/dump.d/module.d"
LOGDUMP_PATH="${LOGDUMP_DIR}/bt-hci-logdump.sh"

# Register BT Device
/usr/etc/bluetooth/bt-dev-start.sh

if !(/usr/bin/hciconfig | /bin/grep hci); then
	echo "BT EDUTM failed. Registering BT device is failed."
	exit 1
fi

if [ -e /usr/sbin/hcidump -a ${HCIDUMP_ENABLE} = "true" ]
then
	# When *#9900# is typed, this is executed to archive logs. #
	/bin/mkdir -p ${LOGDUMP_DIR}
	/bin/cp -f /usr/etc/bluetooth/bt-hci-logdump.sh ${LOGDUMP_PATH}

	/bin/mkdir -p ${HCIDUMP_DIR}/old_hcidump
#	/bin/rm -f ${HCIDUMP_DIR}/old_hcidump/*
	/bin/mv ${HCIDUMP_PATH}* ${HCIDUMP_DIR}/old_hcidump/
	/usr/sbin/hcidump -w ${HCIDUMP_PATH}_`date +%s_%N` &	# You can get unique file name.
#	/usr/sbin/hcidump -w ${HCIDUMP_PATH} &
fi

echo "Configure BT device"
/usr/bin/hcitool cmd 0x3 0x0005 0x02 0x00 0x02

echo "Send BT edutm command"
/usr/bin/hcitool cmd 0x06 0x0003

# Execute BlueZ BT stack
echo "Run bluetoothd"
/usr/lib/bluetooth/bluetoothd &
/usr/bin/bt-service &
/bin/sleep 0.1

/usr/bin/hciconfig hci0 name TIZEN-Mobile

/usr/bin/hciconfig hci0 piscan

if [ -e "/sys/devices/hci0/idle_timeout" ]
then
	echo "Set idle time"
	echo 0 > /sys/devices/hci0/idle_timeout
fi

if [ -e /usr/etc/bluetooth/TIInit_* ]
then
	echo "Reset device"
	/usr/bin/hcitool cmd 0x3 0xFD0C
fi

echo "BT edutm done"

# result
exit 0
