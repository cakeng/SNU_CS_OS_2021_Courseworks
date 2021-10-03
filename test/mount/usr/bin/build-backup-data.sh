#!/bin/bash
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



## build backup data for factory reset


[ $INSTALL_ROOT ] || INSTALL_ROOT="/"
rdir=$INSTALL_ROOT/usr/system/RestoreDir
optdir=$INSTALL_ROOT/opt
CURDIR=`pwd`
BACKUPLIST=`ls -1 $optdir`
EXCLUDE_OPTION=
# For removable preload app
RESTORE_EXCEPTION_LIST=
if [ -e $INSTALL_ROOT/usr/packages/restore_exception.list ]; then
	xlist=$INSTALL_ROOT/usr/packages/restore_exception.list
	RESTORE_EXCEPTION_LIST=`sed -e "s#^\/##g" $xlist`
fi

create_archive() {
	echo "Create_Archive --------------------------------------------"
	mkdir -p $rdir

	BACKUP_FULLPATH=""
	for i in $BACKUPLIST; do
	    BACKUP_FULLPATH="$BACKUP_FULLPATH opt/$i"
	done

	# create tar archives
	echo "create archives... $BACKUP_FULLPATH"
	cd $INSTALL_ROOT
	bash -c	"$BACKUPCMD $BACKUP_FULLPATH $EXCLUDE_OPTION"

	# checksum
	echo "calculate checksum..."
	xpath="! \( -path \"opt/var/tmp/*\" \)"
	for i in $RESTORE_EXCEPTION_LIST; do
		xpath="$xpath ! \( -path \"$i/*\" \)"
	done

	for i in $BACKUP_FULLPATH; do
		bash -c "find $i $xpath -type f -exec md5sum {} \; >> $rdir/checksum.md5"
		bash -c "find $i $xpath -exec /usr/bin/chsmack {} \; >> $rdir/smack_label.txt"
	done

	# workaround for the files with empty smack properies
	sed -i -e "s/: No smack property found//g" $rdir/smack_label.txt

	chmod go-rwx $rdir/* $rdir $rdir/..
}

case "$1" in
tar)
#SCM use opt/var/tmp for temporal files, the files are removed before the binary creation
	EXCLUDE_OPTION="--exclude=opt/var/tmp/*"
	for i in $RESTORE_EXCEPTION_LIST; do
		EXCLUDE_OPTION="$EXCLUDE_OPTION --exclude=$i"
	done
	BACKUPCMD="tar czf $rdir/opt.tar.gz"
	create_archive
	;;
""|zip)
#SCM use opt/var/tmp for temporal files, the files are removed before the binary creation
	EXCLUDE_OPTION="-x "opt/var/tmp/*""
	for i in $RESTORE_EXCEPTION_LIST; do
		EXCLUDE_OPTION="$EXCLUDE_OPTION \"$i/*\""
	done
	BACKUPCMD="zip -yrX- $rdir/opt.zip"
	create_archive
	;;
*)
	echo "Usage: $0 {tar|zip}"
	echo "zip is used by default"
	cd $CURDIR
	exit 2
	;;
esac

cd $CURDIR
## end - building backup data

