#!/bin/bash
PATH=/bin:/usr/bin:/sbin:/usr/sbin
usage()
{
    cat <<EOF
usage:
    $1
  -a|--old_pkg=<old_pkg>
  -b|--new_pkg=<new_pkg>
	-p|--delta_pkg=<delta_pkg>
		[-o|--option=<option>]
		[-h|--help]
Mandatory args:
 -a|--old_pkg         full/absolute delta_pkg of old_pkg
 -b|--new_pkg         full/absolute delta_pkg of new_pkg
 -p|--delta_pkg			delta_pkg for delta dir
Optional args:
  -h,--help         print this help
EOF
    return 0
}

options=$(getopt -o hp:a:b:p: -l help,old_pkg:,new_pkg:,delta_pkg: -- "$@")
if [ $? -ne 0 ]; then
    usage $(basename $0)
    exit 1
fi
eval set -- "$options"

while true
do
    case "$1" in
        -h|--help)	usage $0 && exit 0;;
        -a|--old_pkg)	old_pkg=$2; shift 2;;
        -b|--new_pkg)	new_pkg=$2; shift 2;;
        -p|--delta_pkg)	delta_pkg=$2; shift 2;;
        --)             shift 1; break ;;
        *)              break ;;
    esac
done

if [ -z "$old_pkg" ]; then
    echo "'old_pkg' parameter is required"
    exit 1
fi

if [ -z "$new_pkg" ]; then
    echo "'new_pkg' parameter is required"
    exit 1
fi

temp_delta_repo="/opt/usr/temp_delta/"
outpath="_FILES"

cleanup()
{
	`rm -rf $temp_delta_repo`
}

cleanup

if ! mkdir -p $temp_delta_repo; then
	echo "FAIL: mkdir failed !" >&2
	exit 1
fi

old_pkg_unzip_path=$temp_delta_repo`basename $old_pkg`$outpath
new_pkg_unzip_path=$temp_delta_repo`basename $new_pkg`$outpath

#unzip to ${package}_FILES
if ! unzip -q $old_pkg -d $old_pkg_unzip_path; then
	echo "FAIL: unzip $old_pkg failed!" >&2
	exit 1
fi
if ! unzip -q $new_pkg -d $new_pkg_unzip_path; then
	echo "FAIL: unzip $new_pkg failed!" >&2
	cleanup
	exit 1
fi
