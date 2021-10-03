#!/bin/sh

PATH=/bin:/usr/bin:/sbin:/usr/sbin

# Init security-configuration
/usr/share/security-config/group_id_setting
/usr/share/security-config/set_label
/usr/share/security-config/set_capability

# Migration of cynara DB
# CYNARA_VERSION=$(rpm -qf /usr/bin/cynara  | cut -d "-" -f2)
# cynara-db-migration upgrade -f 0.0.0 -t $CYNARA_VERSION
/usr/sbin/cynara-db-migration upgrade -f 0.0.0 -t 0.14.13

# Migration of security-manager DB
/usr/share/security-manager/db/update.sh

# update global uid in security-manager DB (old : 376, new : 201)
sqlite3 /opt/dbspace/.security-manager.db "UPDATE user_app SET uid="201" WHERE uid="376";"

# start cynara & security-manager
systemctl start cynara
security-manager-policy-reload
/usr/share/security-manager/policy/update.sh
systemctl start security-manager

