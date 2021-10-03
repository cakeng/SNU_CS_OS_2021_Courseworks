#!/bin/sh

export PATH=/bin:/usr/bin:/sbin:/usr/sbin

PRIVACY_LIST="/usr/share/security-config/privacy.list"
PRIVILEGE_GROUP_LIST="/usr/share/security-manager/policy/privilege-group.list"
PRIVILEGE_MOUNT_LIST="/usr/share/security-manager/policy/privilege-mount.list"
DUMMY_DIR="/usr/share/security-manager/dummy"
DUMMY_FILE="/dev/null"

# function : check whether this is a sub directory or file of previous ones : To avoid the meaningless cynara check and bind mount
# args : $1 : privilege, $2 : directory
CHECK_DIR()
{
	while read PRIV_LINE DIR_LINE temp1 TYPE
	do
		if [ "$PRIV_LINE" = "#"* ]
		then
			continue
		fi

		if [ "$PRIV_LINE" = "$1" ] && [ "${2#$DIR_LINE/}" != "$2" ] && [ "$TYPE" = "$DUMMY_DIR" ]
		then
			return 1
		fi

		if [ "$PRIV_LINE" = "$1" ] && [ "$DIR_LINE" = "$2" ]
		then
		 	return 1
		fi
	done < $PRIVILEGE_MOUNT_LIST
	return 0
}

# Create Privacy list tables
# This file will not be removed at the end of the script to use as log file.
if [ -e $PRIVACY_LIST ]
then
	rm $PRIVACY_LIST
fi
touch $PRIVACY_LIST
while read PRIV_LINE PRIV_GID
do
	# skip media and external privileges
	if [ "$PRIV_LINE" = "#"* ] || [ "$PRIV_LINE" = "http://tizen.org/privilege/mediastorage" ] || [ "$PRIV_LINE" = "http://tizen.org/privilege/externalstorage" ]
	then
		continue
	fi
	# check whether this is privacy or not
	if [ "$(sqlite3 /usr/share/privilege-manager/.privilege.db "select distinct is_privacy from privilege_info where privilege_name='$PRIV_LINE' and package_type='core'")" = "1" ]
	then
		echo "$PRIV_LINE  $PRIV_GID" >> $PRIVACY_LIST
	fi
done < $PRIVILEGE_GROUP_LIST

# Read privacy lists from the file.
while read PRIV GROUPNAME
do
	GID=$(getent group $GROUPNAME | cut -d ":" -f 3)
	# FIND directories assigned with this GID
 	findmnt --noheadings --list --output TARGET --types ext4 | xargs -d'\n' -I '{}' find '{}' -mount -type d  -gid "$GID" ! -name "$(printf '*[ \n\t\r]*')" | while read DIR
	do
		# change permissions as every app process can access this
		chmod a+rwx "$DIR"
		# check whether this is the sub directory of previous lists
		CHECK_DIR "$PRIV" "$DIR"
		if [ "$?" = 0 ]
		then
			# append to PRIVILEGE_MOUNT_LIST
			echo "$PRIV  $DIR  -  $DUMMY_DIR" >> $PRIVILEGE_MOUNT_LIST
		fi
	done

	# FIND files assigned with this GID
	findmnt --noheadings --list --output TARGET --types ext4 | xargs -d'\n' -I '{}' find '{}' -mount -type f -gid "$GID" ! -name "$(printf '*[ \n\t\r]*')" | while read FILE
	do
		# change permissions as every app process can access this
		chmod a+rw "$FILE"

		# check whether this is the sub file of previous directory lists
		CHECK_DIR "$PRIV" "$FILE"
		if [ "$?" = 0 ]
		then
			# append to PRIVILEGE_MOUNT_LIST
			echo "$PRIV  $FILE  -  $DUMMY_FILE" >> $PRIVILEGE_MOUNT_LIST
		fi
	done
done < $PRIVACY_LIST
