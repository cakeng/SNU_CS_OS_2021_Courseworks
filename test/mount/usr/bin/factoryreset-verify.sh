#!/bin/sh
#
# Copyright (c) 20014- 2017 Samsung Electronics Co., Ltd.
#
# Contact: MyoungJune Park <mj2004.park@samsung.com>
#   Created by Wonil Choi <wonil22.choi@samsung.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

logfile="/tmp/.verify_fail.log"
logchecksum="/tmp/verify_checksum.log"

CURRENTPATH=`/bin/pwd`
ROOTDIR=/

OPT="opt/"
rdir=usr/system/RestoreDir/

cd ${ROOTDIR}

check_verify () {
# check checksums with target data(restored)
	cd $ROOTDIR; /usr/bin/md5sum -c ${ROOTDIR}${rdir}checksum.md5  > $logchecksum

	if [ $? -ne 0 ];then
		echo "reset verify failed"
		# RESERVED STRING for verification result
		echo "FACTORYRESET VERIFICATION : FAIL"
		/bin/grep FAIL $logchecksum
		/bin/grep FAIL $logchecksum > $logfile
		FACTORY_RESULT="NG,"
# CALLS
		CALLS_DB=`/bin/grep "phone-misc.db:" $logfile`
#		CALLS_APP=`/bin/grep "org.tizen.phone" $logfile`
# contact db also has call logs
		CONTACT_DB=`/bin/grep "contacts-svc.db:" $logfile`
		if [[ "z$CALLS_DB" != "z" || "z$CALLS_APP" != "z" ||
				"z$CONTACT_DB" != "z" ]]; then
			FACTORY_RESULT="${FACTORY_RESULT}CALLS/"
		fi
# SMEMO
		SMEMO_DB=`/bin/grep "smemo.db:" $logfile`
#		SMEMO_APP=`/bin/grep "org.tizen.smemo" $logfile`
		if [[ "z$SMEMO_DB" != "z" || "z$SMEMO_APP" != "z" ]]; then
			FACTORY_RESULT="${FACTORY_RESULT}SMEMO/"
		fi
# MEMO
		MEMO_DB=`/bin/grep "\.memo.db:" $logfile`
#		MEMO_APP=`/bin/grep "org.tizen.memo" $logfile`
		if [[ "z$MEMO_DB" != "z" || "z$MEMO_APP" != "z" ]]; then
			FACTORY_RESULT="${FACTORY_RESULT}MEMO/"
		fi
# SMS/MMS
		MSG_DB=`/bin/grep "msg_service.db:" $logfile`
#		MSG_APP=`/bin/grep "org.tizen.message" $logfile`
#		MSG_SVC=`/bin/grep "msg-service" $logfile`
		if [[ "z$MSG_DB" != "z" || "z$MSG_APP" != "z" ||
				"z$MSG_SVC" != "z" ]]; then
			FACTORY_RESULT="${FACTORY_RESULT}SMS/MMS/"
		fi
# ALARM
		ALARM_DB=`/bin/grep "alarm.db:" $logfile`
#		ALARM_APP=`/bin/grep "org.tizen.clock" $logfile`
		ALARMMGR_DB=`/bin/grep "alarmmgr.db:" $logfile`
		if [[ "z$ALARM_DB" != "z" || "z$ALARM_APP" != "z" ||
				"z$ALARMMGR_DB" != "z" ]]; then
			FACTORY_RESULT="${FACTORY_RESULT}ALARM/"
		fi
# CONTACT
#		CONTACT_APP=`/bin/grep "org.tizen.contacts" $logfile`
#		CONTACT_SVC=`/bin/grep "contacts-svc" $logfile`
		if [[ "z$CONTACT_DB" != "z" || "z$CONTACT_APP" != "z" ||
				"z$CONTACT_SVC" != "z" ]]; then
			FACTORY_RESULT="${FACTORY_RESULT}CONTACT/"
		fi

## Report final results
		if [ "$FACTORY_RESULT" != "NG," ]; then
			echo $FACTORY_RESULT
		fi
	else
		echo "factory reset verify success"
		echo "FACTORYRESET VERIFICATION : OK"
	fi

	/bin/rm -f $logfile
	/bin/rm -f $logchecksum
}

check_verify
