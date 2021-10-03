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

logfile="/opt/.factoryreset.log"
logfile1="/opt/.factoryreset.log.1"
logchecksum="/tmp/factory_reset_checksum.log"

CURRENTPATH=`/bin/pwd`
ROOTDIR=/
USRDATADIR=/opt/usr

OPT="opt/"
rdir=/usr/system/RestoreDir/
FLAG_FTRRST_CP=
FLAG_WITHOUT_CP=

for arg in $@
do
	case "$arg" in
		"--ftrrstcp")
			FLAG_FTRRST_CP="yes"
			;;
		"--withoutcp")
			FLAG_WITHOUT_CP="yes"
			;;
	esac
done

cd ${ROOTDIR}

kill_normal_daemons () {
	LIST=`/bin/ls /proc/`
	for i in $LIST
	do
		if [[ `/usr/bin/expr match "$i" '[0-9]*'` != 0 && -f /proc/${i}/cmdline ]]; then
			cmd=`/bin/cat /proc/${i}/cmdline | /usr/bin/tr '\000' ' ' | /usr/bin/awk '{print $1}'`
			if [ `/usr/bin/expr match "$cmd" '[\/a-zA-Z\-]*'` != 0 ]; then
				pname=`/bin/echo $cmd | /usr/bin/awk '{print $1}' | /usr/bin/awk -F '/' '{print $NF'}`
				if [[ $pname != "factory-reset" &&
					 $pname != "rc.shutdown" &&
					 $pname != "run-factory-reset.sh" &&
					 $pname != "enlightenment" &&
					 $pname != "factory-reset-util" &&
					 $pname != "dbus-daemon" &&
					 $pname != "init" &&
					 $pname != "-sh" &&
					 $pname != "sh" &&
					 $pname != "agetty" &&
					 $pname != "Xorg" &&
					 $pname != "initnormal" &&
					 $pname != "system-recovery" &&
					 $pname != "systemd-logind" &&
					 $pname != "systemd-journald" &&
					 $pname != "systemd-udevd" &&
					 $pname != "mpdecision" &&
					 $pname != "thermal-engine" &&
					 $pname != "rmt_storage" &&
					 $pname != "systemd" ]]
				then
					echo $pname: kill $1 it.
					/usr/bin/killall $1 $pname
				else
					echo $pname: ignore killing.
				fi
			fi
		fi
	done
}

kill_before_reset () {
## disable systemd-releaseagent
	echo /bin/true > /sys/fs/cgroup/vip/release_agent
	/bin/umount -lf /sys/fs/cgroup

## kill processes
	/usr/bin/killall lockscreen
# avoid crash popup
	/usr/bin/killall -STOP deviced
# kill all apps first.
	/usr/bin/killall launchpad_preloading_preinitializing_daemon

	kill_normal_daemons
# some apps revive scim. so kill again.
	/usr/bin/killall -9 scim-launcher isf-panel-efl
	echo "Check and kill again."
	kill_normal_daemons -9
}

check_fail() {
	cur_result=`/bin/grep " : FAIL" ${logfile}`
	old_result=`/bin/grep " : FAIL" ${logfile1}`
	if [[ "z$cur_result" != "z" && "z$old_result" != "z$cur_result" ]]; then
		# reboot and retry
		/bin/sync
		/sbin/reboot
	fi
}

# mount and umount partitions
fs_ready() {
# data in microsd should be preserved.
	/bin/umount -lf ${OPT}/storage/sdcard
	#for encryption. If encrypted, it is mounted one more time as encryptfs.
	/bin/umount -lf ${OPT}/storage/sdcard
# modem binary images should be preserved.
	/bin/umount -lf ${OPT}/modem
# phone usr partition should be reset
	/bin/mkdir -p $USRDATADIR
	/bin/mount $USRDATADIR
	mret=`/bin/grep "$USRDATADIR " /proc/mounts | /usr/bin/awk '{print $1}'`
	#device=`/bin/grep "$USRDATADIR" /etc/fstab | /usr/bin/awk '{print $1}'`
	device=`blkid --match-token LABEL=user -o device`
	device=`/usr/bin/readlink -f $device`
	if [[ "z$mret" != "z" && "$mret" != "$device" ]]; then
		echo "$mret != $device" >> $logfile
		echo "$USRDATADIR may be encrypted : FAIL" >> $logfile
		check_fail
	fi
	if [[ "z$mret" = "z" && "z$device" != "z" ]]; then
		# mount failed. format and remount
		echo "$USRDATADIR mount failed. format and retry to mount again" >> $logfile
		fstype=`/bin/grep "$USRDATADIR " /etc/fstab | /usr/bin/awk '{print $3}'`
		fstype=`blkid --match-token LABEL=user -o device`
		/sbin/mkfs.$fstype $device -F
		/bin/mount -t $fstype $device $USRDATADIR
	fi
	mret=`/bin/grep "$USRDATADIR " /proc/mounts | /usr/bin/awk '{print $2}'`
	if [ "z$mret" = "z" ]; then
		echo "$USRDATADIR MOUNT : FAIL" >> $logfile
		# reboot and retry
		/bin/sync
		/sbin/reboot
	fi
	check_fail
}

disable_keys() {
	key_dir=`/bin/ls -1d /sys/devices/gpio_keys*`
	if [ "z$key_dir" != "z" ]; then
		key_code=`/bin/cat $key_dir/keys`
		echo $key_code > $key_dir/disabled_keys
	fi
	# If cannot disabled keys by sysfs, kill apps about key operations
	# systemctl stop starter
	# /usr/bin/killall volume
	# /usr/bin/killall cluster-home
}

if [ -r ${rdir}opt.tar.gz ]; then
	RSTCMD="/bin/tar xvzf ${rdir}opt.tar.gz -C /"
elif [ -r ${rdir}opt.zip ]; then
	RSTCMD="/usr/bin/unzip -n -X ${rdir}opt.zip"
else
	exit 1
fi

## display ui
cnt=0
while [[ ! -e /tmp/.wm_ready && $cnt -le 10 ]]
do
	echo "waiting window manager $cnt" >> $logfile
	cnt=$(($cnt+1))
	/bin/sleep 1
done

if [ -e /tmp/.wm_ready ]; then
	/usr/bin/factory-reset-util --displayui &
	disable_keys
fi

## start
echo "Factory Resetting..."
echo "*******************" >> $logfile
echo "Start Factory Reset" >> $logfile
/bin/date >> $logfile

## stop lcd on-off and turn lcd on
ss_ready=`/bin/ps -ef | /bin/grep -e "deviced\|system_server" | /bin/grep -v grep`
if [ "z$ss_ready" != "z" ]; then
	/usr/bin/dbus-send --system --type=method_call --print-reply --reply-timeout=10000 \
		--dest=org.tizen.system.deviced	/Org/Tizen/System/DeviceD/Display \
		org.tizen.system.deviced.display.stop
fi

/bin/sync
if [ "z$FLAG_WITHOUT_CP" == "zyes" ]; then
	echo "whithout cp" >> $logfile
else
## shutdown modem
	cp_ok=`/bin/ps -ef | /bin/grep telephony-daemon | /bin/grep -v grep`
	if [[ "z$cp_ok" != "z" && "z$FLAG_FTRRST_CP" == "zyes" ]]; then
		/usr/bin/factory-reset-util --ftrrstcp
		echo "factory reset cp" >> $logfile
	elif [ "z$cp_ok" != "z" ]; then
		# cp service reset is default value.
		/usr/bin/factory-reset-util --svcrstcp
		echo "cp shutdown" >> $logfile
	else
		echo "There is no telephony-daemon" >> $logfile
	fi
fi

# reset audio - If not, some targets make noise when rebooting.
#/usr/bin/sound_server --soundreset

##kill_before_reset

fs_ready
echo "file system ready for factory reset" >> $logfile

# For "Find my mobile" feature, it should work after factory reset.
# So backup its data.
#if [ -r /usr/share/oma-dm-cfg/factory_reset/dm_backup.sh ]; then
#	echo "backup oma dm data"
#	/usr/share/oma-dm-cfg/factory_reset/dm_backup.sh
#fi

## Restore
echo "Delete & Restore System Files..." >> $logfile

#remove all files
rmlist=`/bin/ls -1 ${OPT}`
for i in $rmlist
do
	# except /opt/system. because there are csc configurations and they are
	# updated after binary downloaded. And they should be preserved.
	if [ "$i" != "system" ]; then
		/bin/rm -rf ${OPT}$i
	fi
done

# For Tizen CC (Mobile Device Fundamentals Protection Profile Common Criteria)
if [ -r /usr/bin/resetCCMode ]; then
	echo "MDFPP enabled" >> $logfile
	/usr/bin/resetCCMode >> $logfile
fi

/sbin/fstrim -v $USRDATADIR >> $logfile

# Delete finished. Restore starts here.
cd /
$RSTCMD
echo "$RSTCMD return $?" >> $logfile

mret=`/bin/grep "$USRDATADIR " /proc/mounts | /bin/grep rw | /usr/bin/awk '{print $2}'`
if [ "z$mret" = "z" ]; then
	echo "$USRDATADIR is not RW MOUNTED, RESTORATION : FAIL" >> $logfile
	/bin/rm -rf $USRDATADIR
	check_fail
fi

#check_verify
/usr/bin/factoryreset-verify.sh >> ${logfile}
check_fail

/bin/mkdir -p /opt/var/log/
/bin/touch /opt/var/log/Xorg.0.log

/usr/bin/rstsmack ${rdir}smack_label.txt >> $logfile 2>&1

# Removable preload tpk apps will be installed by package manager
if [ -e $INSTALL_ROOT/usr/packages/restore_exception.list ]; then
	pkgcmd -f
fi

cd ${CURRENTPATH}
/bin/date >> $logfile

## Factory Reset Count
cnt_file="/opt/system/factory-reset-cnt"
if [ -r $cnt_file ]; then
	reset_cnt=`/bin/cat $cnt_file`
	reset_cnt=$(($reset_cnt+1))
	echo $reset_cnt > $cnt_file
else
	echo 1 > $cnt_file
#	/usr/bin/chsmack -a "*" $cnt_file
	/bin/chmod 644 $cnt_file
fi

/bin/sync

echo "Finish FactoryReset..."

