#!/bin/sh
PATH=/bin:/usr/bin:/sbin:/usr/sbin

echo "--------------------------------------"
echo "Update package database..............."
echo "--------------------------------------"

#general update script
/usr/bin/pkg_db_upg
/usr/bin/pkg_upgrade -rof

