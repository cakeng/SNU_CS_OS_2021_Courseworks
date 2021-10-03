#!/bin/sh

MKDIR="/bin/mkdir"
CP="/bin/cp"
RM="/bin/rm"
MV="/bin/mv"
DATE="/bin/date"
GREP="/bin/grep"
CUT="/usr/bin/cut"
PGREP="/usr/bin/pgrep"
BTMON="/usr/bin/btmon"
HCIDUMP="/usr/bin/hcidump"
CHOWN="/bin/chown"

eval $(tzplatform-get TZ_USER_DOWNLOADS)

# When *#9900# is typed, this is executed to archive logs.
LOGDUMP_DIR="/opt/etc/dump.d/module.d"
LOGDUMP_PATH="${LOGDUMP_DIR}/bt-hci-logdump.sh"

# BT HCI Log is saved here
#LOG_BASEDIR=${TZ_USER_DOWNLOADS}
LOG_BASEDIR=/opt/usr/media/Downloads
LOG_DIR="${LOG_BASEDIR}/.bt_dump"

HCIDUMP_LOG_FILENAME="bt_hcidump.log"
BTMON_LOG_FILENAME="btmon.log"

HCIDUMP_LOG_PATH="${LOG_DIR}/${HCIDUMP_LOG_FILENAME}"
BTMON_LOG_PATH="${LOG_DIR}/${BTMON_LOG_FILENAME}"
TMP_PID_FILE="/tmp/.bt_hci_logger.pid"

DUMP_SIZE=5

## Step 1. Check debug mode and force configuration
debug_mode=`/bin/cat /sys/module/sec_debug/parameters/enable`
debug_mode_user=`/bin/cat /sys/module/sec_debug/parameters/enable_user`

case "$1" in
   force)
# Re-initialize the log directory for force mode
      LOG_DIR="${LOG_DIR}/force"
      HCIDUMP_LOG_PATH="${LOG_DIR}/${HCIDUMP_LOG_FILENAME}"
      BTMON_LOG_PATH="${LOG_DIR}/${BTMON_LOG_FILENAME}"
      TMP_PID_FILE="/tmp/.bt_hci_force_logger.pid"
      ;;
   normal)
      if [ ${debug_mode} != '1' -a ${debug_mode_user} != '1' ]
      then
         if [ -e ${LOG_DIR} ]
         then
            ${RM} -rf ${LOG_DIR}
         fi

         if [ ! -e ${TMP_PID_FILE} ]
         then
            exit 0
         fi

         bt_hci_logger_pid=`cat ${TMP_PID_FILE}`
         kill $bt_hci_logger_pid
         ${RM} -f ${TMP_PID_FILE}
         exit 0
      fi
      ;;
   *)
      echo "Usage : bt-run-hci-logger.sh {force | normal} {start | stop} {hcidump | btmon} [keep_old_dump]"
      exit 255
      ;;
esac

## Step 2. Check start / stop parameter
case "$2" in
   start)
      ;;
   stop)
      if [ ! -e ${TMP_PID_FILE} ]
      then
         exit 0
      fi

      bt_hci_logger_pid=`cat ${TMP_PID_FILE}`
      kill $bt_hci_logger_pid
      ${RM} -f ${TMP_PID_FILE}
      exit 0
      ;;
   *)
      echo "Usage : bt-run-hci-logger.sh {force | normal} {start | stop} {hcidump | btmon} [keep_old_dump]"
      exit 255
      ;;
esac

## Step 3. Configure log tool
case "$3" in
   hcidump)
      LOG_TOOL=${HCIDUMP}
      LOG_PATH=${HCIDUMP_LOG_PATH}
      LOG_OPT_END="-c 2 -s ${DUMP_SIZE}"
      ;;
   btmon)
      BTMON_DUMP_SIZE=`expr ${DUMP_SIZE} \* 1000000`
      LOG_TOOL=${BTMON}
      LOG_PATH=${BTMON_LOG_PATH}
      LOG_OPT_END="-C 2 -W ${BTMON_DUMP_SIZE}"
      ;;
   *)
      echo "Usage : bt-run-hci-logger.sh {force | normal} {start | stop} {hcidump | btmon} [keep_old_dump]"
      exit 255
      ;;
esac

## Step 4. Configure keep_old_dump option
case "$4" in
   keep_old_dump)
      KEEP_OLD_DUMP=1
      LOG_PATH="${LOG_PATH}_`${DATE} +%s_%N`"
      ;;
   *)
      KEEP_OLD_DUMP=0
      ;;
esac

## Step 5. Copy a log archive script for all_log_dump.sh
if [ ! -e ${LOGDUMP_PATH} ]
then
   ${MKDIR} -p ${LOGDUMP_DIR}
   ${CP} -f /usr/etc/bluetooth/bt-hci-logdump.sh ${LOGDUMP_PATH}
fi

## Step 6. Check logging base directory
# If it doesn't exist, exit
if [ ! -e ${LOG_BASEDIR} ]
then
   exit 0
fi

## Step 7. Backup old log and Start logging
if [ ! -e ${LOG_DIR}/old_hcidump ]
then
   ${MKDIR} -p ${LOG_DIR}/old_hcidump
   # Make network_fw owner/group to allow systemd.service logging service
   ${CHOWN} -R 551:551 ${LOG_DIR}
fi

if [ ${KEEP_OLD_DUMP} = '0' ]
then
   ${RM} -f ${LOG_DIR}/old_hcidump/*
fi

${MV} ${LOG_DIR}/*.log* ${LOG_DIR}/old_hcidump/;\
${LOG_TOOL} -w ${LOG_PATH} ${LOG_OPT_END} > /dev/null &
echo $! > ${TMP_PID_FILE}

exit 0
