#!/bin/bash

SDB_RULE="99-sdb-switch.rules"
DEST=/opt/usr/data/upgrade

if [ ! -e ${DEST}/${SDB_RULE} ]; then
	/bin/mkdir -p ${DEST}
	/bin/cp /usr/share/upgrade/${SDB_RULE} ${DEST}
fi
