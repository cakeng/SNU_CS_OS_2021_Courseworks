#!/bin/sh
PATH=/bin:/usr/bin:/sbin:/usr/sbin

echo "--------------------------------------"
echo "Clear Data of Apps Skel Directory.........."
echo "--------------------------------------"

_skel_dir="/etc/skel/apps_rw"
_subdir_list="$(dir $_skel_dir)"

for _subdir in $_subdir_list; do
	_data_path="$_skel_dir/$_subdir/data"
	_cache_path="$_skel_dir/$_subdir/cache"
	_shared_data_path="$_skel_dir/$_subdir/shared/data"
	_shared_cache_path="$_skel_dir/$_subdir/shared/cache"
	_shared_trusted_path="$_skel_dir/$_subdir/shared/trusted"

	_target_list=" \
		$_data_path \
		$_cache_path \
		$_shared_data_path \
		$_shared_cache_path \
		$_shared_trusted_path"

	for _target_path in $_target_list; do
		if [ -d "$_target_path" ]; then
			rm -rf $_target_path/*
		fi
	done
done
