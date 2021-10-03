#!/bin/sh

#--------------------------------------
#    bluetooth hci
#--------------------------------------

CHOWN="/bin/chown"

eval $(tzplatform-get TZ_USER_DOWNLOADS)

DUMP_BASE_DIR=$1
BLUETOOTH_DEBUG=${1}/bluetooth

PREV_PWD=${PWD}
#BT_DUMP_DIR=${TZ_USER_DOWNLOADS}/.bt_dump
BT_DUMP_DIR=/opt/usr/media/Downloads/.bt_dump

if [ "$1" = "syslog" ]
then
	DUMP_BASE_DIR=${BT_DUMP_DIR}
	BLUETOOTH_DEBUG=${DUMP_BASE_DIR}/bluetooth
fi

BT_DUMP_TMP_DIR=/tmp/bt_dump
LOG_FILE="bt_hcidump.log"

process_btdump()
{
	if [ -e btmon.log.1 -a -e btmon.log ]
	then
		/usr/bin/tail -c +17 btmon.log > btmon.log_bin
		/bin/cat btmon.log.1 btmon.log_bin > final.log
		/usr/bin/btsnoop -s final.log
		if [ $? -eq 0 ]
		then
			/bin/rm -f btmon.log_bin btmon.log.1 btmon.log final.log
			LOG_FILE="btsnoop_*.log"
		else
			/bin/rm -f btmon.log_bin btmon.log.1 btmon.log
			/bin/mv final.log btmon.log
			LOG_FILE=""
		fi
	elif [ -e bt_hcidump.log.1 -a -e bt_hcidump.log ]
	then
		/usr/bin/tail -c +17 bt_hcidump.log > bt_hcidump.log_bin
		/bin/cat bt_hcidump.log.1 bt_hcidump.log_bin > bt_hcidump.log
		/bin/rm -f bt_hcidump.log_bin bt_hcidump.log.1
	elif [ -e btmon.log ]
	then
		/usr/bin/btsnoop -s btmon.log
		if [ $? -eq 0 ]
		then
			/bin/rm -f btmon.log
			LOG_FILE="btsnoop_*.log"
		else
			LOG_FILE=""
		fi
	fi

	if [ "${LOG_FILE}a" != "a" ]
	then
		/usr/bin/rename .log .cfa ${LOG_FILE}
	fi
}

if [ ! -e ${BT_DUMP_DIR} ]
then
	if [ "$1" = "syslog" ]
	then
		/bin/mkdir -p ${BT_DUMP_DIR}
		/bin/chown 200:200 ${BT_DUMP_DIR}
	else
		exit 0
	fi
fi

if [ "$1" = "syslog" ]
then
	cp /var/log/messages ${BT_DUMP_DIR}/messages_`date "+%b_%d_%H:%M:%S_%Y"`
	cp /var/log/messages.0 ${BT_DUMP_DIR}/messages.0_`date "+%b_%d_%H:%M:%S_%Y"`
	# Skip the orginal bt_dump extract part
	exit 0
fi

if [ ${DUMP_BASE_DIR} ]
then
	cd ${DUMP_BASE_DIR}
fi

/bin/mkdir -p ${BLUETOOTH_DEBUG}
${CHOWN} 200:200 ${BLUETOOTH_DEBUG}

/bin/mkdir -p ${BT_DUMP_TMP_DIR}
/bin/cp -rf ${BT_DUMP_DIR}/* ${BT_DUMP_TMP_DIR}

cd ${BT_DUMP_TMP_DIR}
process_btdump

if [ -e "${BT_DUMP_TMP_DIR}/old_hcidump" ]
then
	cd ${BT_DUMP_TMP_DIR}/old_hcidump
	process_btdump
fi

cd ${BT_DUMP_TMP_DIR}
/bin/tar czf ${BLUETOOTH_DEBUG}/bt_dump.tar.gz *

cd ${BLUETOOTH_DEBUG}
${CHOWN} 200:200 ${BLUETOOTH_DEBUG}/bt_dump.tar.gz
/bin/rm -rf ${BT_DUMP_TMP_DIR}

cd ${PREV_PWD}
