#!/bin/sh
PATH=/bin:/usr/bin:/sbin:/usr/sbin

source /etc/tizen-platform.conf

PARSER_DB_NAME=.pkgmgr_parser.db
PARSER_DB_PATH=$TZ_SYS_DB/$PARSER_DB_NAME

function migrate_cert_db() {
	echo "PRAGMA user_version=30001;" | sqlite3 $TZ_SYS_DB/.pkgmgr_cert.db
}

function migrate_parser_db() {
	local dbpath=$1

	echo -e "CREATE TABLE IF NOT EXISTS package_appdefined_privilege_info (\n" \
	"  package TEXT NOT NULL,\n" \
	"  privilege TEXT NOT NULL,\n" \
	"  license TEXT,\n" \
	"  type TEXT NOT NULL,\n" \
	"  PRIMARY KEY(package, privilege, type)\n" \
	"  FOREIGN KEY(package)\n" \
	"  REFERENCES package_info(package) ON DELETE CASCADE);" | sqlite3 $dbpath

	echo -e "CREATE TABLE IF NOT EXISTS package_update_info (\n" \
		"  package TEXT NOT NULL,\n" \
		"  update_version TEXT NOT NULL,\n" \
		"  update_type TEXT NOT NULL DEFAULT 'none',\n" \
		"  PRIMARY KEY(package)\n" \
		"  FOREIGN KEY(package)\n" \
		"  REFERENCES package_info(package) ON DELETE CASCADE);" | sqlite3 $dbpath

	echo -e "CREATE TABLE IF NOT EXISTS package_app_app_control_privilege (\n" \
		"  app_id TEXT NOT NULL,\n" \
		"  app_control TEXT NOT NULL,\n" \
		"  privilege TEXT NOT NULL,\n" \
		"  FOREIGN KEY(app_id,app_control)\n" \
		"  REFERENCES package_app_app_control(app_id,app_control) ON DELETE CASCADE);" | sqlite3 $dbpath

	echo -e "CREATE TABLE IF NOT EXISTS package_app_data_control_privilege (\n" \
		"  providerid TEXT,\n" \
		"  privilege TEXT NOT NULL,\n" \
		"  type TEXT NOT NULL,\n" \
		"  PRIMARY KEY(providerid, privilege, type)\n" \
		"  FOREIGN KEY(providerid, type)\n" \
		"  REFERENCES package_app_data_control(providerid, type) ON DELETE CASCADE);" | sqlite3 $dbpath

	echo -e "ALTER TABLE package_app_data_control RENAME TO package_app_data_control_backup;" | sqlite3 $dbpath

	echo -e "CREATE TABLE package_app_data_control (\n" \
	"  app_id TEXT NOT NULL,\n" \
	"  providerid TEXT NOT NULL,\n" \
	"  access TEXT NOT NULL,\n" \
	"  type TEXT NOT NULL,\n" \
	"  trusted TEXT NOT NULL,\n" \
	"  PRIMARY KEY(providerid, type)\n" \
	"  FOREIGN KEY(app_id)\n" \
	"  REFERENCES package_app_info(app_id) ON DELETE CASCADE);" | sqlite3 $dbpath

	echo -e "ALTER TABLE package_app_info ADD COLUMN app_setup_appid TEXT;" | sqlite3 $dbpath

	#seperate migration of app data control table by access type for backward compatibility.
	echo -e "INSERT INTO package_app_data_control(app_id, providerid, access, type, trusted) " \
	"  SELECT app_id, providerid, access, type, 'false' FROM package_app_data_control_backup WHERE access='readwrite' COLLATE NOCASE;" | sqlite3 $dbpath
	echo -e "INSERT INTO package_app_data_control(app_id, providerid, access, type, trusted) " \
	"  SELECT app_id, providerid, access, type, 'false' FROM package_app_data_control_backup WHERE access='writeonly' COLLATE NOCASE;" | sqlite3 $dbpath
	echo -e "INSERT INTO package_app_data_control(app_id, providerid, access, type, trusted) " \
	"  SELECT app_id, providerid, access, type, 'false' FROM package_app_data_control_backup WHERE access!='readwrite' COLLATE NOCASE AND access!='writeonly' COLLATE NOCASE;" | sqlite3 $dbpath
	echo -e "DROP TABLE package_app_data_control_backup;" | sqlite3 $dbpath

	echo "DROP TABLE IF EXISTS package_app_icon_section_info;" | sqlite3 $dbpath
	echo "DROP TABLE IF EXISTS package_app_image_info;" | sqlite3 $dbpath
	echo "DROP TABLE IF EXISTS package_app_app_permission;" | sqlite3 $dbpath
	echo "DROP TABLE IF EXISTS package_app_share_allowed;" | sqlite3 $dbpath
	echo "DROP TABLE IF EXISTS package_app_share_request;" | sqlite3 $dbpath

	echo "PRAGMA user_version=30001;" | sqlite3 $dbpath
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
migrate_cert_db

pkg_upgrade -rof
