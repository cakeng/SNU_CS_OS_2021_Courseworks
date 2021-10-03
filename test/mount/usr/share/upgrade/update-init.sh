#!/bin/sh
#
# RW update initialize script
#
PATH=/bin:/usr/bin:/sbin:/usr/sbin
RW_MACRO=/usr/share/upgrade/rw-update-macro.inc
RW_UPDATE=/usr/share/upgrade/update.sh
DEBUG_MODE=/opt/usr/.upgdebug

if [ -f $RW_MACRO ]; then
	source $RW_MACRO
	get_version_info
fi

if [ ! "$OLD_VER" = "$NEW_VER" ]; then
	# Restore rpm db
	rm -rf /var/lib/rpm/*
	restore_backup_file -f /opt/var/lib/rpm
fi

# Permission Update for shared directories
/etc/gumd/useradd.d/91_user-dbspace-permissions.post owner

sleep 10
if [ -f $DEBUG_MODE ]; then
	exit
fi

exec /bin/sh $RW_UPDATE
