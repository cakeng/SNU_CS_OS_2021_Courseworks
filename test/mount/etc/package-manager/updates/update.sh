#!/bin/sh

source /etc/tizen-platform.conf

PARSER_DB_NAME=.pkgmgr_parser.db
PARSER_DB_PATH=$TZ_SYS_DB/$PARSER_DB_NAME
DB_VERSION_FILE_PATH="/etc/package-manager/pkg_db_version.txt"
DB_VERSION_OLD="`\"sqlite3\" \"$PARSER_DB_PATH\" 'PRAGMA user_version;'`"
DB_VERSION_NEW="`cat $DB_VERSION_FILE_PATH`"
DB_VERSION_TIZEN24=1
DB_VERSION_TIZEN30_DEFAULT=30000
UPDATE_SCRIPT_LOCATION="/etc/package-manager/updates/"
UPDATE_SCRIPT_PREFIX="upgrade_to_"

#execute script from DB_VERSION_OLD to DB_VERSION_OLD+1 until DB_VERSION_OLD+1 reaches DB_VERSION_NEW

[ $DB_VERSION_OLD -eq $DB_VERSION_NEW ] && echo "Pkgmgr database is already up to date v$DB_VERSION_NEW" && exit
[ $DB_VERSION_OLD -gt $DB_VERSION_NEW ] && echo "Pkgmgr database downgrading is not supported." && exit

echo "Pkgmgr database current version: $DB_VERSION_OLD, target version: $DB_VERSION_NEW"

#if old version is less than 1, upgrade to 30000, default version of tizen_3.0
if [ $DB_VERSION_OLD -le $DB_VERSION_TIZEN24 ]; then
	echo "Updating $PARSER_DB_PATH to $DB_VERSION_TIZEN30_DEFAULT"
	exec "$UPDATE_SCRIPT_LOCATION/$UPDATE_SCRIPT_PREFIX$DB_VERSION_TIZEN30_DEFAULT.sh"
	DB_VERSION_OLD=30000
fi

for i in `seq $(($DB_VERSION_OLD+1)) $DB_VERSION_NEW`
do
    echo "Updating $PARSER_DB_PATH to $i (target version is $DB_VERSION_NEW)"
    UPDATE_SCRIPT="$UPDATE_SCRIPT_LOCATION/$UPDATE_SCRIPT_PREFIX$i.sh"
    [ ! -e "$UPDATE_SCRIPT" ] && echo "Can't find script $UPDATE_SCRIPT" && exit 1
    exec $UPDATE_SCRIPT
done
