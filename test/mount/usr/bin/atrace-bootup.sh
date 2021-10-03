#!/bin/bash
PATH=/bin:/usr/bin:/sbin:/usr/sbin
SCRIPT=`basename ${BASH_SOURCE[0]}`

#Help function
function HELP {
  echo -e \\n"Help documentation for ${SCRIPT}."\\n
  echo -e "Basic usage: $SCRIPT <tag> ..."\\n
  echo -e "Example: $SCRIPT sched freq wm am"\\n
  echo -e "-h  --Displays this help message. No further functions are performed."\\n
  exit 1
}

CONF="/etc/ttrace.conf"

SPACE=" "
TAGLIST=""
DEFTAGS=""

NUMARGS=$#
if [ $NUMARGS -eq 0 ]; then
  TAGLIST=$DEFTAGS
else
	shift $((OPTIND-1))  #This tells getopts to move on to the next argument.
	while [ $# -ne 0 ]; do
		PARAM=$1
		TAGLIST=$TAGLIST$SPACE$PARAM
		shift
	done
fi

echo "TAGLIST is: $TAGLIST"
echo "$TAGLIST" > "$CONF"

sync
sleep 1
reboot -f

exit 0
