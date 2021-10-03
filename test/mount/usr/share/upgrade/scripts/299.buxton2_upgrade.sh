#!/bin/sh
#
# buxton upgrade initialize script (3.0 -> 4.0)
#

DB_DIR=/var/lib/buxton2

# The UID of buxton has changed
chown -R buxton:buxton $DB_DIR

buxton2ctl remove-garbage-data system

systemctl start buxton2

buxton2ctl security-disable

