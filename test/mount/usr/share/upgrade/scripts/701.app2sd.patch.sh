#!/bin/sh
PATH=/bin:/usr/bin:/sbin:/usr/sbin

source /etc/tizen-platform.conf
DEFAULT_USER=$TZ_SYS_DEFAULT_USER

APP2SD_DB_NAME=.app2sd.db
APP2SD_DB_PATH=$TZ_SYS_DB/$APP2SD_DB_NAME
DB_RESULT_FILE=/tmp/result.log
OPT_MEDIA=$TZ_SYS_MEDIA

TMP_MOUNTPOINT=/tmp/mountpoint
MAP_DEVICE_PATH=/dev/mapper

SMACK_PREFIX=User::Pkg::
SMACK_POSTFIX=::RO

function create_table(){
	echo "CREATE TABLE IF NOT EXISTS app2sd_info (pkgid TEXT NOT NULL, password TEXT NOT NULL, filename TEXT NOT NULL, uid INTEGER, PRIMARY KEY(pkgid, uid));" |
	sqlite3 $APP2SD_DB_PATH > $DB_RESULT_FILE
}

function drop_old_table(){
	echo "DROP TABLE app2sd;" |
	sqlite3 $APP2SD_DB_PATH > $DB_RESULT_FILE
}

function migrate_db_data(){
	local userid=`id -u $DEFAULT_USER`
	echo "INSERT INTO app2sd_info(pkgid, password, filename, uid) SELECT pkgid, password, '', '$userid' from app2sd;" |
	sqlite3 $APP2SD_DB_PATH > $DB_RESULT_FILE
}

function change_label() {
	local label=$1
	local path=$2
	chsmack -r -a $1 $2
}

function change_db_label() {
	change_label System $APP2SD_DB_PATH
}

function migrate_file() {
	local filename=$1
	local filepath=$2
	local cryptsetup=`/sbin/cryptsetup isLuks /opt/media/SDCardA1/app2sd/$filename;echo $?;`
	local passwd=`echo "SELECT password from app2sd_info where pkgid='$1';" | sqlite3 $APP2SD_DB_PATH`

	if [ $cryptsetup = 1 ]
	then
		/bin/echo $passwd | /sbin/cryptsetup -M plain -c aes-cbc-plain -h plain open /opt/media/SDCardA1/app2sd/$filename $filename
		mkdir $TMP_MOUNTPOINT
		mount $MAP_DEVICE_PATH/$filename $TMP_MOUNTPOINT

		change_label $SMACK_PREFIX$filename$SMACK_POSTFIX $TMP_MOUNTPOINT/bin
		change_label $SMACK_PREFIX$filename$SMACK_POSTFIX $TMP_MOUNTPOINT/lib
		change_label $SMACK_PREFIX$filename$SMACK_POSTFIX $TMP_MOUNTPOINT/res
		change_label $SMACK_PREFIX$filename$SMACK_POSTFIX $TMP_MOUNTPOINT/lost+found

		umount $MAP_DEVICE_PATH/$filename
		/sbin/cryptsetup luksClose $MAP_DEVICE_PATH/$filename
	fi
}

function migrate_app2sd_file() {
	#for each folder in /opt/media/
	for FOLDER1 in `ls $OPT_MEDIA`
	do
		#skip it if it is not directory
		if [ ! -d $OPT_MEDIA/$FOLDER1 ]
		then
			continue
		fi

		for FOLDER2 in `ls $OPT_MEDIA/$FOLDER1`
		do
			#if its name is not app2sd, skip
			if [ $FOLDER2 != 'app2sd' ]
			then
				continue
			fi

			for APP2SD_FILE in `ls $OPT_MEDIA/$FOLDER1/$FOLDER2`
			do
				#if it is not file, skip it
				if [ -d $OPT_MEDIA/$FOLDER1/$FODLER2/$APP2SD_FILE ]
				then
					continue
				fi

				#call functions to check
				echo "migrate : $APP2SD_FILE $OPT_MEDIA/$FOLDER1/$FOLDER2"
				migrate_file $APP2SD_FILE $OPT_MEDIA/$FOLDER1/$FOLDER2
			done
		done
	done
}

#invoke functions
echo "APP2SD migration"
create_table
migrate_db_data
drop_old_table
change_db_label
migrate_app2sd_file
