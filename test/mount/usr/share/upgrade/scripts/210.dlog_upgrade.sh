#!/bin/sh
PATH=/bin:/usr/bin:/sbin:/usr/sbin
source /usr/share/upgrade/rw-update-macro.inc
source /etc/tizen-platform.conf

#----------------------------------#
# dlog upgrade script (3.0 -> 4.0) #
#----------------------------------#

# Macro
CONF_PATH=$TZ_SYS_ETC
DLOG_CONF_D_PATH=$CONF_PATH/dlog.conf.d

if [ ! -e $DLOG_CONF_D_PATH ]; then
    restore_backup_file -r $DLOG_CONF_D_PATH/
fi

# Alter conf file
rm -f $CONF_PATH/dlog.conf.logger
rm -f $CONF_PATH/dlog.conf.pipe
rm -f $CONF_PATH/dlog.conf
restore_backup_file $CONF_PATH/dlog.conf.logger
restore_backup_file $CONF_PATH/dlog.conf.pipe
restore_backup_file $CONF_PATH/dlog.conf

