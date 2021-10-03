#!/bin/sh
PATH=/bin:/usr/bin:/sbin:/usr/sbin

source /etc/tizen-platform.conf

CERT_DB_NAME=.pkgmgr_cert.db
CERT_BACKUP_DB_NAME=.pkgmgr_cert_backup.db
CERT_BACKUP_DB_PATH=$TZ_SYS_DB/$CERT_BACKUP_DB_NAME
CERT_DB_PATH=$TZ_SYS_DB/$CERT_DB_NAME
CERT_TEMP_FILEPATH=/tmp

PARSER_DB_NAME=.pkgmgr_parser.db
PARSER_BACKUP_DB_NAME=.pkgmgr_parser_backup.db
PARSER_DB_PATH=$TZ_SYS_DB/$PARSER_DB_NAME
PARSER_BACKUP_DB_PATH=$TZ_SYS_DB/$PARSER_BACKUP_DB_NAME
DB_RESULT_FILE=/tmp/result.log

OPT_USR_APPS=/opt/usr/apps

#define owner user
DEFAULT_USER=$TZ_SYS_DEFAULT_USER

#define /opt/usr/home/owner
DEFAULT_USER_HOME=$TZ_SYS_HOME/$DEFAULT_USER

#define /opt/usr/home/owner/apps_rw
DEFAULT_USER_APPS_RW=$DEFAULT_USER_HOME/apps_rw

#define /opt/share/packages
DEFAULT_PKG_MANIFEST_LOCATION=$TZ_SYS_RW_PACKAGES

#define /opt/usr/globalapps
DEFAULT_PKG_APP_LOCATION=$TZ_SYS_RW_APP


DEFAULT_RO_OWNER_GROUP=tizenglobalapp:root
DEFAULT_MANIFEST_SMACK_LABEL=System

DEFAULT_RW_OWNER_GROUP=owner:users
DEFAULT_RW_SMACK_LABEL=User::Pkg::
DEFAULT_RO_SMACK_LABEL=User::Home

TIZEN_MANIFEST=tizen-manifest.xml

OWNER_SYSTEM_SHARE=owner:system_share
TRUSTED_LABEL=User::Author::1

RESTRICTION_DBPATH=/var/lib/package-manager
RESTRICTION_DBNAME=restriction.db
#----------------------------------
# upgrade script for pkgmgr
#----------------------------------

function backup_db(){
	echo "#backup previous DB"
	mv $PARSER_DB_PATH $PARSER_BACKUP_DB_PATH
	mv $CERT_DB_PATH $CERT_BACKUP_DB_PATH
}

function create_restriction_db(){
	echo "#create restriction db"
	local restriction_db=$RESTRICTION_DBPATH/$RESTRICTION_DBNAME
	mkdir -p $RESTRICTION_DBPATH
	echo "PRAGMA journal_mode=WAL;
		CREATE TABLE restriction (uid INTEGER NOT NULL, pkgid TEXT NOT NULL, mode INTEGER NOT NULL, UNIQUE(uid, pkgid));" |
	sqlite3 $restriction_db
}

function remove_modified_manifest(){
	echo "#remove modified manifest"
	rm -rf $DEFAULT_PKG_MANIFEST_LOCATION/*
}

function remove_unregistered_pkg(){
	#remove pkg folder which is not registered at pkg db
	ls $OPT_USR_APPS/ | while read FOLDER
	do
		result=$(sqlite3 $PARSER_BACKUP_DB_PATH "SELECT COUNT(*) FROM package_info WHERE package='$FOLDER';")
		if [ $result != "1" ]
		then
			echo "delete unregistered package directory $OPT_USR_APPS/$FOLDER"
			rm -r $OPT_USR_APPS/$FOLDER
		fi
	done
}

function move_user_tpk_ro_files(){
	#this copy will copy whole things include userdata
	local package=$1
	cp -af $OPT_USR_APPS/$package $DEFAULT_PKG_APP_LOCATION/
	chown -R $DEFAULT_RO_OWNER_GROUP $DEFAULT_PKG_APP_LOCATION/$package

}

function move_user_tpk_rw_files(){
	local package=$1

	local target="$DEFAULT_USER_APPS_RW/$package"
	local source="$OPT_USR_APPS/$package"

	rm -rf $source/shared/cache
	cp -Rf $source/cache/* $target/cache/
	cp -Rf $source/data/* $target/data/
	cp -Rf $source/shared/* $target/shared/
	rm -rf $source
}

function copy_user_tpk_manifest(){
	local package=$1
	cp $DEFAULT_PKG_APP_LOCATION/$1/$TIZEN_MANIFEST $DEFAULT_PKG_MANIFEST_LOCATION/$package.xml
}

function move_user_tpk_files(){
	echo "#move user TPK's files"
	echo "SELECT package FROM package_info WHERE package_readonly='false' COLLATE NOCASE AND package_type COLLATE NOCASE IN ('tpk', 'rpm');" |
	sqlite3 $PARSER_BACKUP_DB_PATH > $DB_RESULT_FILE

	while read package
	do
		echo "processing user tpk $package..."
		move_user_tpk_ro_files $package
		copy_user_tpk_manifest $package
	done < $DB_RESULT_FILE
	rm -f $DB_RESULT_FILE
}

function move_user_wgt_ro_files(){
	#this copy will copy whole things include userdata
	local package=$1
	cp -af --no-preserve=ownership $OPT_USR_APPS/$package $DEFAULT_PKG_APP_LOCATION/
	chown -R $DEFAULT_RO_OWNER_GROUP $DEFAULT_PKG_APP_LOCATION/$package
}

function move_user_wgt_rw_files(){
	local package=$1

	local target="$DEFAULT_USER_APPS_RW/$package"
	local source="$OPT_USR_APPS/$package"

	rm -rf $source/shared/cache
	cp -Rf $source/cache/* $target/cache/
	cp -Rf $source/data/* $target/data/
	cp -Rf $source/shared/* $target/shared/
	rm -r $source
}


function move_user_wgt_files(){
	echo "#move user WGT's files"
	echo "SELECT package FROM package_info WHERE package_readonly='false' COLLATE NOCASE AND package_type='wgt' COLLATE NOCASE;" |
	sqlite3 $PARSER_BACKUP_DB_PATH > $DB_RESULT_FILE

	while read package
	do
		echo "processing user wgt $package..."
		move_user_wgt_ro_files $package
	done < $DB_RESULT_FILE
	rm -f $DB_RESULT_FILE

}

function initdb(){
	echo "#pkg_initdb"
	pkg_initdb --ro --partial-rw

	mkdir -m 770 -p /opt/dbspace/user/5001
	chmod 755 /opt/dbspace/user
	chsmack -r -a User::Home /opt/dbspace/user
	chown $OWNER_SYSTEM_SHARE /opt/dbspace/user/5001

	pkg_initdb --uid 5001
}

function remove_files_for_deleted_packages(){
	#delete userdata of packages which are removed in 3.0
	echo "#delete userdata of removed packages"
	echo "ATTACH DATABASE '$PARSER_BACKUP_DB_PATH' AS backup;
	    SELECT package FROM backup.package_info WHERE package_readonly='true' COLLATE NOCASE AND
	    package NOT IN (SELECT package FROM package_info);" |
	sqlite3 $PARSER_DB_PATH > $DB_RESULT_FILE

	while read package
	do
		echo "rm -r $OPT_USR_APPS/$package"
		rm -r $OPT_USR_APPS/$package
		done < $DB_RESULT_FILE
	rm -f $DB_RESULT_FILE
}

function move_preload_pkg_userdata(){
	echo "#move preload pkg's userdata"
	echo "ATTACH DATABASE '$PARSER_BACKUP_DB_PATH' AS backup;
	    SELECT package FROM backup.package_info WHERE package_readonly='true' COLLATE NOCASE AND
	    package IN (SELECT package FROM package_info);" |
	sqlite3 $PARSER_DB_PATH > $DB_RESULT_FILE
	while read package
	do
		echo "processing preload pkg $package..."
		local source="$OPT_USR_APPS/$package"
		local target="$DEFAULT_USER_APPS_RW/$package"
		rm -rf $source/shared/cache
		cp -Rf $source/cache/* $target/cache/
		cp -Rf $source/data/* $target/data/
		cp -Rf $source/shared $target/shared/

		rm -rf $source
	done < $DB_RESULT_FILE
	rm -f $DB_RESULT_FILE
}

function disable_preload_pkg(){
	echo "#disable preload rpm, tpk pkg"
	echo "ATTACH DATABASE '$PARSER_BACKUP_DB_PATH' AS backup;
	    SELECT package FROM backup.package_info WHERE package_readonly='true' COLLATE NOCASE AND package_type!='wgt' COLLATE NOCASE AND package_disable='true' COLLATE NOCASE AND
	    package IN (SELECT package FROM package_info);" |
	sqlite3 $PARSER_DB_PATH > $DB_RESULT_FILE

	while read package
	do
		echo "disable preload pkg $package..."
		tpk-backend -D $package --preload
	done < $DB_RESULT_FILE
	rm -f $DB_RESULT_FILE

	echo "#disable preload wgt pkg"
	echo "ATTACH DATABASE '$PARSER_BACKUP_DB_PATH' AS backup;
	    SELECT package FROM backup.package_info WHERE package_readonly='true' COLLATE NOCASE AND package_type='wgt' COLLATE NOCASE AND package_disable='true' COLLATE NOCASE AND
	    package IN (SELECT package FROM package_info);" |
	sqlite3 $PARSER_DB_PATH > $DB_RESULT_FILE

	while read package
	do
		echo "disable preload wgt $package..."
		wgt-backend -D $package --preload
	done < $DB_RESULT_FILE
	rm -f $DB_RESULT_FILE
}

function disable_user_pkg(){
	echo "#disable user pkg"
	echo ".separator \" \"
	    ATTACH DATABASE '$PARSER_BACKUP_DB_PATH' AS backup;
	    SELECT package, package_type FROM backup.package_info WHERE package_readonly='false' COLLATE NOCASE AND package_type !='rpm' COLLATE NOCASE AND package_disable='true' COLLATE NOCASE AND
	    package IN (SELECT package FROM package_info);" |
	sqlite3 $PARSER_DB_PATH > $DB_RESULT_FILE

	while read package type
	do
		echo "disable user pkg $package..."
		echo "$type-backend -D $package"
		$type-backend -D $package
	done < $DB_RESULT_FILE
	rm -f $DB_RESULT_FILE
}

function remove_backup_db(){
	rm $PARSER_BACKUP_DB_PATH
	rm $CERT_BACKUP_DB_PATH
}

function init_user_tpk_preload_rw_packages() {
	echo "#init tpk preload rw packages"
	echo ".separator \" \"
	    SELECT package FROM package_info WHERE package_readonly='false' COLLATE NOCASE AND package_preload='true' COLLATE NOCASE AND package_type COLLATE NOCASE IN ('tpk', 'rpm');" |
	sqlite3 $PARSER_BACKUP_DB_PATH > $DB_RESULT_FILE

	while read package
	do
		echo "init tpk preload rw package $package..."
		echo "SELECT cert_info FROM package_cert_index_info WHERE cert_id=(SELECT dist_root_cert FROM package_cert_info WHERE package='$package');" |
		sqlite3 $CERT_BACKUP_DB_PATH > $CERT_TEMP_FILEPATH/$package.txt

		tpk-backend -y $package --preload-rw
		rm -f $CERT_TEMP_FILEPATH/$package.txt
		migrate_cert_info $package
		move_user_tpk_rw_files $package
	done < $DB_RESULT_FILE
	rm -f $DB_RESULT_FILE
}

function init_user_wgt_preload_rw_packages() {
	echo "#init wgt preload rw packages"
	echo ".separator \" \"
	    SELECT package FROM package_info WHERE package_readonly='false' COLLATE NOCASE AND package_preload='true' COLLATE NOCASE AND package_type='wgt';" |
	sqlite3 $PARSER_BACKUP_DB_PATH > $DB_RESULT_FILE

	while read package
	do
		echo "init wgt preload rw package $package..."
		wgt-backend -y $package --preload-rw
		move_user_wgt_rw_files $package
	done < $DB_RESULT_FILE
	rm -f $DB_RESULT_FILE
}

function insert_cert_index_info() {
	local cert_index=$1
	if [ ! $cert_index ] || [ $cert_index -eq 0 ]; then
		echo "given cert_index is null"
		return
	fi

	local cert_value=`sqlite3 $CERT_BACKUP_DB_PATH "SELECT cert_info FROM package_cert_index_info WHERE cert_id=$cert_index"`
	if [ ! $cert_value ]; then
		echo "retrieved cert value with id [$cert_index] is null."
		return
	fi

	sqlite3 $CERT_DB_PATH "INSERT OR REPLACE INTO package_cert_index_info(cert_info, cert_id, cert_ref_count)
		VALUES('$cert_value',
		(SELECT cert_id FROM package_cert_index_info WHERE cert_info='$cert_value'),
		COALESCE(((SELECT cert_ref_count FROM package_cert_index_info WHERE cert_info='$cert_value')+1), 1))"
}

function insert_cert_info() {
	local package=$1
	local author_root_index=$2
	local author_im_index=$3
	local author_signer_index=$4
	local dist_root_index=$5
	local dist_im_index=$6
	local dist_signer_index=$7
	local dist2_root_index=$8
	local dist2_im_index=$9
	local dist2_signer_index=

	local dist_root_value=`sqlite3 $CERT_DB_PATH "ATTACH database '$CERT_BACKUP_DB_PATH' as backup;
		SELECT cert_id FROM package_cert_index_info WHERE cert_info=
		(SELECT cert_info FROM backup.package_cert_index_info WHERE cert_id='$dist_root_index')"`
	local dist_im_value=`sqlite3 $CERT_DB_PATH "ATTACH database '$CERT_BACKUP_DB_PATH' as backup;
		SELECT cert_id FROM package_cert_index_info WHERE cert_info=
		(SELECT cert_info FROM backup.package_cert_index_info WHERE cert_id='$dist_im_index')"`
	local dist_signer_value=`sqlite3 $CERT_DB_PATH "ATTACH database '$CERT_BACKUP_DB_PATH' as backup;
		SELECT cert_id FROM package_cert_index_info WHERE cert_info=
		(SELECT cert_info FROM backup.package_cert_index_info WHERE cert_id='$dist_signer_index')"`

	local dist2_root_value=`sqlite3 $CERT_DB_PATH "ATTACH database '$CERT_BACKUP_DB_PATH' as backup;
		SELECT cert_id FROM package_cert_index_info WHERE cert_info=
		(SELECT cert_info FROM backup.package_cert_index_info WHERE cert_id='$dist2_root_index')"`
	local dist2_im_value=`sqlite3 $CERT_DB_PATH "ATTACH database '$CERT_BACKUP_DB_PATH' as backup;
		SELECT cert_id FROM package_cert_index_info WHERE cert_info=
		(SELECT cert_info FROM backup.package_cert_index_info WHERE cert_id='$dist2_im_index')"`
	local dist2_signer_value=`sqlite3 $CERT_DB_PATH "ATTACH database '$CERT_BACKUP_DB_PATH' as backup;
		SELECT cert_id FROM package_cert_index_info WHERE cert_info=
		(SELECT cert_info FROM backup.package_cert_index_info WHERE cert_id='$dist2_signer_index')"`

	#update dist, dist2 value of package_cert_info determined by given pkg
	local is_update_needed=""
	local query="UPDATE package_cert_info SET "
	if [ "$dist_root_value" != "" ]; then
		is_update_needed="true"
		query=$query"dist_root_cert='$dist_root_value'"
	fi

	if [ "$dist_im_value" != "" ]; then
		is_update_needed="true"
		query=$query", dist_im_cert='$dist_im_value'"
	fi

	if [ "$dist_signer_value" != "" ]; then
		is_update_needed="true"
		query=$query", dist_signer_cert='$dist_signer_value'"
	fi

	if [ "$dist2_root_value" != "" ]; then
		is_update_needed="true"
		query=$query"dist2_root_cert='$dist2_root_value'"
	fi

	if [ "$dist2_im_value" != "" ]; then
		is_update_needed="true"
		query=$query", dist2_im_cert='$dist2_im_value'"
	fi

	if [ "$dist2_signer_value" != "" ]; then
		is_update_needed="true"
		query=$query", dist2_signer_cert='$dist2_signer_value'"
	fi

	if [ "$is_update_needed" != "true" ]; then
		echo "no update needed"
		return
	fi

	query=$query" WHERE package='$package'"
	sqlite3 $CERT_DB_PATH "$query"
}

function migrate_cert_info() {
	local package=$1

	#get certificate value from old cert db and insert into new cert db
	echo ".separator \" \"
		SELECT author_root_cert, author_im_cert, author_signer_cert, dist_root_cert, dist_im_cert, dist_signer_cert, dist2_root_cert, dist2_im_cert, dist2_signer_cert
		FROM package_cert_info WHERE package='$package';" |
	sqlite3 $CERT_BACKUP_DB_PATH > $CERT_TEMP_FILEPATH/$package.txt

	while read author_root_cert author_im_cert author_signer_cert dist_root_cert dist_im_cert dist_signer_cert dist2_root_cert dist2_im_cert dist2_signer_cert
	do
		insert_cert_index_info $author_root_cert
		insert_cert_index_info $author_im_cert
		insert_cert_index_info $author_signer_cert
		insert_cert_index_info $dist_root_cert
		insert_cert_index_info $dist_im_cert
		insert_cert_index_info $dist_signer_cert
		insert_cert_index_info $dist2_root_cert
		insert_cert_index_info $dist2_im_cert
		insert_cert_index_info $dist2_signer_cert

		insert_cert_info $package $author_root_cert $author_im_cert $author_signer_cert $dist_root_cert $dist_im_cert $dist_signer_cert $dist2_root_cert $dist2_im_cert $dist2_signer_cert
	done < $CERT_TEMP_FILEPATH/$package.txt
	rm -f $CERT_TEMP_FILEPATH/$package.txt
}

function init_user_tpk_packages() {
	echo "#init user tpk packages"
	echo ".separator \" \"
	    SELECT package FROM package_info WHERE package_readonly='false' COLLATE NOCASE AND
	    package_preload='false' COLLATE NOCASE AND package_type='tpk';" |
	sqlite3 $PARSER_BACKUP_DB_PATH > $DB_RESULT_FILE

	while read package
	do
		echo "init user tpk package $package..."

		echo "SELECT cert_info FROM package_cert_index_info WHERE cert_id=
		(SELECT dist_root_cert FROM package_cert_info WHERE package='$package');" |
		sqlite3 $CERT_BACKUP_DB_PATH > $CERT_TEMP_FILEPATH/$package.txt

		tpk-backend -y $package
		rm -f $CERT_TEMP_FILEPATH/$package.txt

		migrate_cert_info $package
		move_user_tpk_rw_files $package
	done < $DB_RESULT_FILE
	rm -f $DB_RESULT_FILE
}

function init_user_wgt_packages(){
	echo "#init user wgt packages"
	echo ".separator \" \"
	    SELECT package FROM package_info WHERE package_readonly='false' COLLATE NOCASE AND package_type='wgt';" |
	sqlite3 $PARSER_BACKUP_DB_PATH > $DB_RESULT_FILE

	while read package
	do
		echo "init user wgt package $package..."
		wgt-backend -y $package
		move_user_wgt_rw_files $package
	done < $DB_RESULT_FILE
	rm -f $DB_RESULT_FILE
}

function migrate_external_info(){
	echo "#migrate external storage info"
	echo "ATTACH DATABASE '$PARSER_BACKUP_DB_PATH' AS backup;
		UPDATE package_info set installed_storage='installed_external' WHERE package IN
		(SELECT package FROM backup.package_info WHERE installed_storage='installed_external' COLLATE NOCASE);" |
	sqlite3 $PARSER_DB_PATH
}

backup_db

create_restriction_db

remove_modified_manifest
remove_unregistered_pkg

move_user_tpk_files
move_user_wgt_files

initdb
init_user_tpk_packages
init_user_tpk_preload_rw_packages
init_user_wgt_packages
init_user_wgt_preload_rw_packages

remove_files_for_deleted_packages
move_preload_pkg_userdata

disable_preload_pkg
disable_user_pkg
migrate_external_info

remove_backup_db
