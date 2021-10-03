#!/bin/bash
STATUS_DIR="/opt/usr/data/upgrade"
FOTA_DIR="$STATUS_DIR/fota"
VERSION_FILE="/opt/etc/version"
DOWNLOAD_DELTA=$1
DELTA_TAR="$FOTA_DIR/delta.tar"
UPG_VERIFIER="/usr/sbin/upg-verifier"

flash_pre_image() {
	echo "Flash images for update..."
	DEVICE="/dev/mmcblk0"
	CONFIG_FILE="update.cfg"

	/bin/tar xvfp $DELTA_TAR -C "$FOTA_DIR" $CONFIG_FILE
	if [ ! -e "$FOTA_DIR/$CONFIG_FILE" ]; then
		echo "There is no $CONFIG_FILE"
		return
	fi

	while read PART_NAME DELTA_NAME TYPE DEV OFFSET SIZE HASH1 HASH2
	do
		if [ "$TYPE" = "PRE_UA" ]; then
			/bin/tar xvfp $DELTA_TAR -C $FOTA_DIR $DELTA_NAME
			if [ ! -e "$FOTA_DIR/$DELTA_NAME" ]; then
				echo "There is no delta for $PART_NAME"
				continue
			fi

			EMMC_DEVICE="/dev/mmcblk0"
			PART_NAME_L=$(echo $PART_NAME | /bin/tr '[:upper:]' '[:lower:]')
			DEV_NUM=$(/sbin/partx -s $EMMC_DEVICE | grep $PART_NAME_L | \
					{ read NUM REST; echo $NUM; })
			if [ -z "$DEV_NUM" ]; then
				DEV_NUM=$(/sbin/blkid -L $PART_NAME_L -o device | grep $EMMC_DEVICE | \
						sed 's/\/dev\/mmcblk0p//')
			fi
			if [ -z "$DEV_NUM" ]; then
				DEV=${DEV}
			else
				DEV="${EMMC_DEVICE}p${DEV_NUM}"
			fi

			echo "Flashing $DELTA_NAME..."
			dd if="$FOTA_DIR/$DELTA_NAME" of="$DEV" bs=1024
			rm -f $FOTA_DIR/$DELTA_NAME

			# Remove updated partition from cfg
			/bin/cat "$FOTA_DIR/$CONFIG_FILE" | /bin/sed /^$PART_NAME/d \
				> "$FOTA_DIR/${CONFIG_FILE}_tmp"
			/bin/mv "$FOTA_DIR/${CONFIG_FILE}_tmp" "$FOTA_DIR/$CONFIG_FILE"

			/bin/tar --delete --file=$DELTA_TAR $CONFIG_FILE
			/bin/tar rvf $DELTA_TAR -C $FOTA_DIR $CONFIG_FILE
		fi
	done < "$FOTA_DIR/$CONFIG_FILE"
}

write_version_info() {
	OLD_VER=$(cat /etc/config/model-config.xml | grep platform.version\" \
			| sed -e 's/.*>\(.*\)<.*/\1/' | head -1)
	i=0
	VER=(0 0 0 0)
	for ENT in $(echo "$OLD_VER" | tr "." "\n"); do
		VER[$i]=$ENT
		((i++))
	done
	CVT_VER=${VER[0]}.${VER[1]}.${VER[2]}.${VER[3]}

	echo "OLD_VER=$CVT_VER" > $VERSION_FILE
}

run_pre_script() {
	PRE_SCRIPT_NAME=pre.sh
	PRE_SCRIPT_PATH=$FOTA_DIR/$PRE_SCRIPT_NAME

	/bin/tar xvfp $DELTA_TAR -C $FOTA_DIR $PRE_SCRIPT_NAME

	if [ -e $PRE_SCRIPT_PATH ]; then
		/bin/sh $PRE_SCRIPT_PATH
		rm $PRE_SCRIPT_PATH
	fi
}

# Check fota directory
if [ ! -d "$FOTA_DIR" ]; then
	echo "Create fota dir..."
	/bin/mkdir -p "$FOTA_DIR"
fi

if [ ! -d "$STATUS_DIR" ]; then
	echo "Create status dir..."
	/bin/mkdir -p "$STATUS_DIR"
fi

# Record version info in target if it doesn't exist
ls "$VERSION_FILE"
if [ $? -ne 0 ]; then
	write_version_info
fi

echo "Copy delta.tar..."
/bin/cp $DOWNLOAD_DELTA $DELTA_TAR
sync

# Verify delta.tar
if [ -e "$UPG_VERIFIER" ]; then
	echo "Package verifier is found. Verify $DELTA_TAR"
	$UPG_VERIFIER $DELTA_TAR
	if [ $? -ne 0 ]; then
		echo "Update package verification FAILED..."
		echo 5 > "$STATUS_DIR"/result
		exit 1
	else
		echo "Update package verification PASSED!"
	fi
fi

# Run pre-script if exist
run_pre_script

# Flash images
#  - in case of some new image was included
#  - in case of some image should be flashed before update
flash_pre_image

# Extract delta.ua
echo "Extract delta.ua..."
/bin/tar xvfp $DELTA_TAR -C "$FOTA_DIR" delta.ua
sync
sleep 1

# FOTA: /usr/bin/rw-update-prepare.sh

# Write delta saved path
echo "Write paths..."
echo "$FOTA_DIR" > "$STATUS_DIR/DELTA.PATH"
echo "$(dirname $DOWNLOAD_DELTA)" > "$STATUS_DIR/DOWNLOAD.PATH"
sync

# go to fota mode
echo "Go TOTA update..."
/sbin/reboot fota
