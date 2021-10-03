#!/bin/sh
RW_MACRO=/usr/share/upgrade/rw-update-macro.inc

if [ -e ${RW_MACRO} ]; then
	source ${RW_MACRO}
	write_version_info
fi
