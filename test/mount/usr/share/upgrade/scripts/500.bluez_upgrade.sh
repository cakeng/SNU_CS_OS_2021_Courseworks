#!/bin/sh
PATH=/bin:/usr/bin:/sbin:/usr/sbin

#------------------------------------------#
# bluetoothd patch for upgrade             #
#------------------------------------------#

# Change the smack label for BT chip and paired info
source /usr/share/upgrade/rw-update-macro.inc
get_version_info

if [ $OLD_VER == "3.0" ]; then
	chsmack -a "_" /var/lib/bluetooth
	chsmack -a "_" /var/lib/bluetooth* -r
fi
