#!/bin/sh

OLD_VER=
NEW_VER=
OLD_VER_INFO="/opt/etc/version"

# Convert version to 4 digits
convert_version() {
	i=0
	VER=(0 0 0 0)
	for ENT in $(echo "$1" | tr "." "\n"); do
		VER[$i]=$ENT
		((i++))
	done
	CVT_VER=${VER[0]}.${VER[1]}.${VER[2]}.${VER[3]}
}

get_version_info() {
	if [ -f $OLD_VER_INFO ]; then
		source $OLD_VER_INFO
	fi
	NEW_VER=$(cat /etc/config/model-config.xml | grep platform.version\" \
			| sed -e 's/.*>\(.*\)<.*/\1/' | head -1)
	convert_version $NEW_VER
	NEW_VER=$CVT_VER
}

write_version_info() {
	get_version_info
	echo "OLD_VER=$NEW_VER" > $OLD_VER_INFO
}

BACKUP_ZIP="/usr/system/RestoreDir/opt.zip"

restore_from_zip() {

	TARGET_FILE=$1
	TARGET_DIR=$(dirname /$TARGET_FILE)

	echo "restore_from_zip: $TARGET_FILE"
	if [ ! -d $TARGET_DIR ]; then
		mkdir -p $TARGET_DIR
	fi

	# The attributes of directory can not be overwritten by unzip.
	# Unzip the directory into temp path and copy it to original path.
	if [ "z${TARGET_FILE: -1}" = "z/" ]; then
		RESTORE_DIR_PATH="/tmp/restored_dir"
		mkdir -p $RESTORE_DIR_PATH
		unzip -oX $BACKUP_ZIP $TARGET_FILE -d $RESTORE_DIR_PATH > /dev/null
		cp -af $RESTORE_DIR_PATH/$TARGET_FILE $TARGET_DIR
		rm -rf $RESTORE_DIR_PATH
	else
		unzip -oX $BACKUP_ZIP $TARGET_FILE -d / > /dev/null
	fi

	# Restore smack label
	TMP=$(mktemp /tmp/smackinfo.XXXXXX)
	PATH_FOR_SMACK=$(echo $TARGET_FILE | sed -e "s/\/$//")
	SMACK_VAL=$(grep "$PATH_FOR_SMACK " /usr/system/RestoreDir/smack_label.txt | \
			{ read FILE SMACK; echo $SMACK; })
	if [ "z$SMACK_VAL" = "z" ]; then
		echo "No smack label for $PATH_FOR_SMACK"
	else
		echo "/$PATH_FOR_SMACK $SMACK_VAL" > $TMP
		rstsmack $TMP
	fi
	rm $TMP
}

restore_backup_file() {

	OVERWRITE=
	RESTORE_PATH=

	while [ "z$1" != "z" ]; do
		case $1 in
		-f )
			OVERWRITE=$1
			;;
		-r )
			;;
		* )
			RESTORE_PATH=$1
			;;
		esac
		shift
	done

	if [ "z$RESTORE_PATH" = "z" ]; then
		echo "There is no file to restore"
		return
	fi

	if [ ! "z${RESTORE_PATH:0:1}" = "z/" ]; then
		echo "Full path of file is required"
		return
	fi

	if [ -e "$RESTORE_PATH" ]; then
		if [ ! "z$OVERWRITE" = "z" ]; then
			echo "Warning: $RESTORE_PATH already exists. It will be overwritten"
		else
			echo "Error: $RESTORE_PATH already exists"
			return
		fi
	fi

	# Check if the target file is backed up
	PATH_FOR_ZIP=$(echo $RESTORE_PATH | sed -e "s/^\///")
	FOUND_FILES=$(unzip -l $BACKUP_ZIP | awk '{print $4}' | \
			grep "^$PATH_FOR_ZIP")
	FOUND_FILE=$(echo "$FOUND_FILES" | \
			grep -E "$PATH_FOR_ZIP$|$PATH_FOR_ZIP/$")
	if [ "z$FOUND_FILE" = "z" ]; then
		echo "Error: $RESTORE_PATH was not backed up"
		return
	fi

	echo "restore_backup_file: $RESTORE_PATH"
	if [ ! "z${FOUND_FILE: -1}" = "z/" ]; then
		restore_from_zip $FOUND_FILE
	else
		for FILE in $FOUND_FILES; do
			restore_from_zip $FILE
		done
	fi
}
