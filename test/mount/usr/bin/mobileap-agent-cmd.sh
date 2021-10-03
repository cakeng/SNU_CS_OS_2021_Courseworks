#!/bin/sh
PATH=/bin:/usr/bin:/sbin:/usr/sbin

TABLE_FILTER="filter"
TETH_FILTER_FW="teth_filter_fw"

DATA_USAGE_FILE="/tmp/tethering_data_usage.txt"

src=$2
dest=$3

get_tx_data_usage()
{
	/usr/sbin/iptables -t ${TABLE_FILTER} -L ${TETH_FILTER_FW} -vx |
	/usr/bin/grep -v DROP |
	/usr/bin/grep "${src}[ ]*${dest}" |
	/usr/bin/awk '{ print $2 }' > ${DATA_USAGE_FILE}
}

get_rx_data_usage()
{
	/usr/sbin/iptables -t ${TABLE_FILTER} -L ${TETH_FILTER_FW} -vx |
	/usr/bin/grep -v DROP |
	/usr/bin/grep "${dest}[ ]*${src}" |
	/usr/bin/awk '{ print $2 }' > ${DATA_USAGE_FILE}
}

case $1 in
"get_tx_data_usage")
get_tx_data_usage
;;
"get_rx_data_usage")
get_rx_data_usage
;;
*)
/bin/echo mobileap-agent-cmd.sh [get_tx_data_usage] [get_rx_data_usage]
exit 1
;;
esac

