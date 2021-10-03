#!/bin/sh
#
# RW update script
#
PATH=/bin:/usr/bin:/sbin:/usr/sbin

UPI_RW_UPDATE_ERROR=fa1a

TMP_DIR=/tmp/upgrade
UPDATE_DIR=/usr/share/upgrade
PATCH_DIR=/usr/share/upgrade/scripts
UPDATE_DATA_DIR=/opt/usr/data/upgrade
LOG_FILE=${UPDATE_DATA_DIR}/rw_update.log
RESULT_FILE=${UPDATE_DATA_DIR}/result
SDB_RULE=${UPDATE_DATA_DIR}/99-sdb-switch.rules
VERSION_FILE=/opt/etc/version
RW_MACRO=${UPDATE_DIR}/rw-update-macro.inc
RUN=/bin/sh

RW_GUI=
RW_ANI=/usr/bin/rw-update-ani

#------------------------------------------------
#	shell script verity check
#	return 0 : pass
#	return 1 : no entry in rw-script.list
#	return 2 : verity fail
#------------------------------------------------
Verity_Check() {

	if [ "z$1" = "z" ]; then
		echo "Input Shell Script Null" >> ${LOG_FILE}
		return 1
	fi

	SC_FILE=`/usr/bin/basename $1`
	SC_LIST=${UPDATE_DIR}/rw-script.list
	if [ -f ${SC_LIST} ]; then
		grep ${SC_FILE} ${SC_LIST} > /dev/null 2>&1
		if [ "$?" = "0" ]; then
			ret=`/usr/bin/md5sum "$1"`
			mret=($(/bin/echo $ret))
			md5result=${mret[0]}

			md5list=`/usr/bin/grep ${SC_FILE} ${SC_LIST} | /usr/bin/awk -F' ' '{print $2}'`
			if [ "$md5result" = "$md5list" ]; then
				echo "[PASS    ] ${SC_FILE} verity check" >> ${LOG_FILE}
				return 0
			else
				echo "[MISMATCH] ${SC_FILE} md5sum" >> ${LOG_FILE}
				return 2
			fi
		else
			echo "[No entry] ${SC_FILE} in ${SC_LIST}" >> ${LOG_FILE}
			return 1
		fi
	else
		echo "No such file ${SC_LIST}" >> ${LOG_FILE}
		return 1
	fi
}

#------------------------------------------------
#	main
#------------------------------------------------

# Check GUI availability
if [ -e ${RW_ANI} ]; then
	RW_GUI=1
fi

mkdir -p ${RECOVERY_DIR}

echo "System RW update: rw update started" > ${LOG_FILE}

# Execute update scripts
if [ ! -d ${PATCH_DIR} ]
then
	echo "FAIL: Upgrade directory does not exist" >> ${LOG_FILE}
	echo "${UPI_RW_UPDATE_ERROR}" > ${RESULT_FILE}
else
	if [ "${RW_GUI}" = "1" ]; then
		progress=0
		total=`ls -l ${PATCH_DIR} | grep -c '^-'`
		mkdir -p ${TMP_DIR}
		echo ${total} > ${TMP_DIR}/total
		export XDG_RUNTIME_DIR=/run
		export TBM_DISPLAY_SERVER=1
		/usr/bin/rw-update-ani --wait &
	fi

	PATCHES=`/bin/ls ${PATCH_DIR}`

	for PATCH in ${PATCHES}; do
		if [ "${RW_GUI}" = "1" ]; then
			progress=$((progress+1))
			echo ${progress} > ${TMP_DIR}/progress
		fi
		Verity_Check ${PATCH_DIR}/${PATCH}
		# Skip in case of 'No entry' only
		if [ "$?" != "1" ]; then
			${RUN} ${PATCH_DIR}/${PATCH}
		fi
	done

	sync

	echo "SUCCESS: Upgrade successfully finished" >> ${LOG_FILE}
fi

if [ -e ${SDB_RULE} ]; then
	rm ${SDB_RULE}
fi

if [ -e ${VERSION_FILE} ]; then
	rm ${VERSION_FILE}
	if [ -e ${RW_MACRO} ]; then
		source ${RW_MACRO}
		write_version_info
	fi
fi

# Reboot
reboot -f
