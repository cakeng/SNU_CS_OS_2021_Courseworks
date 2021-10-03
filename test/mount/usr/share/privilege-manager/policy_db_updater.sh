#!/bin/sh -e

PATH=/bin:/usr/bin:/sbin:/usr/sbin

. /etc/tizen-platform.conf

DB_NAME=${TZ_SYS_DB}/.policy.db
DB_NAME_JOURNAL=${TZ_SYS_DB}/.policy.db-journal
MDM_BLACKLIST=${TZ_SYS_RO_SHARE}/security-config/mdm_blacklist
globalapp_uid=`cat /etc/passwd | grep $TZ_SYS_GLOBALAPP_USER | cut -d ":" -f3`
if [ ! -e $DB_NAME ]; then
	echo "Creating $DB_NAME ..."
	touch $DB_NAME
	if [ -e $DB_NAME_JOURNAL ]; then
		rm $DB_NAME_JOURNAL
	fi
	touch $DB_NAME_JOURNAL

	echo "Creating PREVENT_LIST table ..."
	sqlite3 $DB_NAME "CREATE TABLE PREVENT_LIST (UID NUMERIC not null, PACKAGE_TYPE NUMERIC , PRIVILEGE_NAME TEXT not null, UNIQUE(UID, PACKAGE_TYPE, PRIVILEGE_NAME));"
	echo "Creating DISABLE_LIST table...."
	sqlite3 $DB_NAME "CREATE TABLE DISABLE_LIST (UID NUMERIC not null, PRIVILEGE_NAME TEXT not null, UNIQUE(UID, PRIVILEGE_NAME));"
fi

if [ -a $MDM_BLACKLIST ]; then
	echo "mdm blacklist exist"
	IFS=$'\n'
	for i in `cat $MDM_BLACKLIST`
	do
		temp=`echo $i | awk '/^#/'`
    	if [ ! "$temp" = "" ]
    	then
    	    continue
	    fi
		echo "insert $i"
		sqlite3 $DB_NAME "insert or ignore into disable_list values ('$globalapp_uid', '${i}');"
	done

	echo "Check inserted data"
	echo "DPM blacklist..."
	sqlite3 $DB_NAME "select * from prevent_list"
	echo ""
	echo "MDM blacklist..."
	sqlite3 $DB_NAME "select * from disable_list"
else
	echo "mdm blacklist not exist"
fi
