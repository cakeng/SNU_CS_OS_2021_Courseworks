#!/bin/sh
BACKUP_HELPER="/usr/share/upgrade/rw-update-macro.inc"
ETC_DIR="/opt/etc"
UID_REGULAR_USER_MIN=5001
UID_REGULAR_USER_MAX=10000

source $BACKUP_HELPER

# Restore etc links
cp -af "$ETC_DIR/passwd" "$ETC_DIR/old_passwd"
cp -af "$ETC_DIR/shadow" "$ETC_DIR/old_shadow"
cp -af "$ETC_DIR/group" "$ETC_DIR/old_group"
cp -af "$ETC_DIR/gshadow" "$ETC_DIR/old_gshadow"
restore_backup_file -f "$ETC_DIR/passwd"
restore_backup_file -f "$ETC_DIR/passwd-"
restore_backup_file -f "$ETC_DIR/passwd.old"
restore_backup_file -f "$ETC_DIR/shadow"
restore_backup_file -f "$ETC_DIR/shadow-"
restore_backup_file -f "$ETC_DIR/shadow.old"
restore_backup_file -f "$ETC_DIR/group"
restore_backup_file -f "$ETC_DIR/group-"
restore_backup_file -f "$ETC_DIR/group.old"
restore_backup_file -f "$ETC_DIR/gshadow"
restore_backup_file -f "$ETC_DIR/gshadow-"
restore_backup_file -f "$ETC_DIR/gshadow.old"

awk -F':' '('${UID_REGULAR_USER_MIN}' < $3 && $3 < '${UID_REGULAR_USER_MAX}'){system("/usr/bin/getent shadow " $1 " || /usr/bin/sed -n " NR "," NR "p '${ETC_DIR}'/old_shadow >> '${ETC_DIR}'/shadow")}' $ETC_DIR/old_passwd
awk -F':' '('${UID_REGULAR_USER_MIN}' < $3 && $3 < '${UID_REGULAR_USER_MAX}'){system("/usr/bin/getent passwd " $1 " || /usr/bin/echo " $0 " >> '${ETC_DIR}'/passwd")}' $ETC_DIR/old_passwd

rm $ETC_DIR/old_passwd
rm $ETC_DIR/old_shadow
rm $ETC_DIR/old_group
rm $ETC_DIR/old_gshadow
