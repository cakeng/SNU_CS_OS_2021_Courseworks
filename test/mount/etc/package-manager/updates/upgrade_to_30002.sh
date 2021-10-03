#!/bin/sh
PATH=/bin:/usr/bin:/sbin:/usr/sbin

source /etc/tizen-platform.conf

PARSER_DB_NAME=.pkgmgr_parser.db
PARSER_DB_PATH=$TZ_SYS_DB/$PARSER_DB_NAME

function migrate_parser_db() {
	local dbpath=$1

	echo -e "ALTER TABLE package_app_app_control ADD visibility TEXT NOT NULL DEFAULT 'local-only'" | sqlite3 $dbpath
}

function migrate_user_db() {
	#get each user db path and call migrate_parser_db for each of it

	find $TZ_SYS_DB/user -name $PARSER_DB_NAME | while read DBPATH
	do
		migrate_parser_db $DBPATH
	done
}

migrate_parser_db $PARSER_DB_PATH
migrate_user_db
