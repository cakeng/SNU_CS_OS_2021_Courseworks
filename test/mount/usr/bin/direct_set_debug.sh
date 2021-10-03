#!/bin/sh

PATH=/bin:/usr/bin:/sbin:/usr/sbin

load_usb_gadget() {
	### For legacy usb drivers ###
	if [ -e /sys/class/usb_mode/usb0 ]; then
		echo 0 > /sys/class/usb_mode/usb0/enable
		echo 04e8 > /sys/class/usb_mode/usb0/idVendor
		echo $1 > /sys/class/usb_mode/usb0/idProduct
		echo $2 > /sys/class/usb_mode/usb0/funcs_fconf
		echo $3 > /sys/class/usb_mode/usb0/funcs_sconf
		echo 239 > /sys/class/usb_mode/usb0/bDeviceClass
		echo 2 > /sys/class/usb_mode/usb0/bDeviceSubClass
		echo 1 > /sys/class/usb_mode/usb0/bDeviceProtocol
		echo 1 > /sys/class/usb_mode/usb0/enable
	fi
}

unload_usb_gadget() {
	### For legacy usb drivers ###
	if [ -e /sys/class/usb_mode/usb0 ]; then
		echo 0 > /sys/class/usb_mode/usb0/enable
	fi
}

sdb_set() {
	load_usb_gadget "6860" "" "sdb"
	/usr/bin/systemctl start sdbd.service
	/usr/bin/vconftool set -t int memory/sysman/usb_status 2 -f
	echo "SDB enabled"
}

sdb_unset() {
	unload_usb_gadget
	/usr/bin/vconftool set -t int memory/sysman/usb_status 0 -f
	/usr/bin/systemctl stop sdbd.service
	echo "SDB disabled"
}

show_options() {
	echo "direct_set_debug.sh: usage:"
	echo "    --help       This message"
	echo "    --sdb-set    Load sdb without usb-manager"
	echo "    --sdb-unset  Unload sdb without usb-manager"
}

case "$1" in
"--sdb-set")
	sdb_set
	;;

"--sdb-unset")
	sdb_unset
	;;

"--help")
	show_options
	;;

*)
	echo "Wrong parameters. Please use option --help to check options "
	;;
esac
