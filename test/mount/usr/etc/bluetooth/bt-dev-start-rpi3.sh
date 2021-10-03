#!/bin/sh
PATH=/bin:/usr/bin:/sbin:/usr/sbin

# Script for registering Broadcom UART BT device
BT_UART_DEVICE=/dev/ttyAMA0
BT_CHIP_TYPE=bcm43xx
BT_MAC_FILE=/opt/etc/.bd_addr

BT_PLATFORM_DEFAULT_HCI_NAME="TIZEN-Mobile"
UART_SPEED=921600

HCI_CONFIG=/usr/bin/hciconfig
HCI_ATTACH=/usr/bin/hciattach

if [ ! -e "$BT_UART_DEVICE" ]
then
	mknod $BT_UART_DEVICE c 204 64
fi

GEN_BDADDR(){
        echo "BT Mac addr generates randomly."
        MAC_PRE=$(echo "00:02:")
        MAC_POST=$(/usr/bin/openssl rand -hex 4 | sed 's/\(..\)/\1:/g; s/.$//')
        echo "Random : $MAC_PRE$MAC_POST"
        BT_MAC=$MAC_PRE$MAC_POST
}

if [ ! -e "$BT_MAC_FILE" ]
then
	# Set BT address
	GEN_BDADDR
	echo $BT_MAC > ${BT_MAC_FILE}
else
	BT_MAC=$(cat ${BT_MAC_FILE})
fi

echo $BT_MAC

echo "Check for Bluetooth device status"
if ($HCI_CONFIG | grep hci); then
	echo "Bluetooth device is UP"
	$HCI_CONFIG hci0 up
else
	echo "Bluetooth device is DOWN"
	echo "Registering Bluetooth device"

	# Attaching Broadcom device
	if ($HCI_ATTACH $BT_UART_DEVICE $BT_CHIP_TYPE $UART_SPEED noflow nosleep $BT_MAC); then
		sleep 0.1
		$HCI_CONFIG hci0 up
		$HCI_CONFIG hci0 name $BT_PLATFORM_DEFAULT_HCI_NAME
		$HCI_CONFIG hci0 sspmode 1
		echo "HCIATTACH success"
	else
		echo "HCIATTACH failed"
	fi
fi
