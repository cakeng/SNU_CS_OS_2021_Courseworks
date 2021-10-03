#!/bin/sh -e

export PATH=/sbin:/usr/sbin:/bin:/usr/bin

. /etc/tizen-platform.conf

SRC_PATH=$TZ_SYS_SMACK/accesses.d
DSC_PATH=$TZ_SYS_VAR/security-manager/rules
MRG_PATH=$TZ_SYS_VAR/security-manager/rules-merged/rules.merged
SHARED_RO_PATH=$DSC_PATH/2x_shared_ro

echo "Running migration process"

if [ ! -e $MRG_PATH ]
then
    echo "Moving files from ${SRC_PATH} to ${DSC_PATH}"
    mv ${SRC_PATH}/app_* ${SRC_PATH}/pkg_* ${SRC_PATH}/author_* ${DSC_PATH}
    echo "Merging files from ${DSC_PATH} to ${MRG_PATH}"
    cat ${DSC_PATH}/* > ${MRG_PATH}
fi

if [ ! -e $SHARED_RO_PATH ]
then
    echo "Moving SharedRO rules to ${SHARED_RO_PATH}"
    cat ${DSC_PATH}/pkg_* | grep 'User::App.*SharedRO' > ${SHARED_RO_PATH}
    sed '/User::App.*SharedRO/d' -i ${DSC_PATH}/pkg_*
fi

echo "Migration process was finished"
