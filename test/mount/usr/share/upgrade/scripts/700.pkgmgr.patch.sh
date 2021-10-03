#!/bin/sh

source /etc/tizen-platform.conf

exec "/etc/package-manager/updates/update.sh"

/usr/bin/pkg_upgrade -rof
