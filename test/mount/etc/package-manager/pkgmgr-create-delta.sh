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
 -a|--old_pkg		full/absolute delta_pkg of old_pkg
 -b|--new_pkg		full/absolute delta_pkg of new_pkg
 -p|--delta_pkg		delta_pkg for delta dir
Optional args:
 -h,--help			print this help
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
        -h|--help)		usage $0 && exit 0;;
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
temp_delta_dir="tmp"
XDELTA="xdelta3"
diff_file="/opt/usr/temp_delta/difffile.txt"

cleanup()
{
	`rm -rf $temp_delta_repo`
}

which()
{
	local aflag sflag ES a opt

	OPTIND=1
	while builtin getopts as opt ; do
		case "$opt" in
		a)	aflag=-a ;;
		s)	sflag=1 ;;
		?)	echo "which: usage: which [-as] command [command ...]" >&2
			exit 2 ;;
		esac
	done

	(( $OPTIND > 1 )) && shift $(( $OPTIND - 1 ))

	# without command arguments, exit with status 1
	ES=1

	# exit status is 0 if all commands are found, 1 if any are not found
	for command; do
		# if $command is a function, make sure we add -a so type
		# will look in $PATH after finding the function
		a=$aflag
		case "$(builtin type -t $command)" in
		"function")	a=-a;;
		esac

		if [ -n "$sflag" ]; then
			builtin type -p $a $command >/dev/null 2>&1
		else
			builtin type -p $a $command
		fi
		ES=$?
	done

	return $ES
}

old_pkg_unzip_path=$temp_delta_repo`basename $old_pkg`$outpath
new_pkg_unzip_path=$temp_delta_repo`basename $new_pkg`$outpath
sample_delta=$temp_delta_repo$temp_delta_dir

while read line
	do
		if [[ "$line" =~ "differ" ]]; then
			if ! which $XDELTA; then
				echo "FAIL: $XDELTA is not installed!" >&2
				cleanup
				exit 1
			else
				break
			fi
		fi
done < $diff_file

#create new delta directory
if ! mkdir $sample_delta; then
    echo "FAIL: mkdir !" >&2
    cleanup
    exit 1
fi

#create separate temporary xmls for <modified>, <added>, <removed> which will be merged to one delta_info.xml
`touch $sample_delta/modified.xml`
`echo "<modify-files>" >> $sample_delta/modified.xml`

`touch $sample_delta/added.xml`
`echo "<add-files>" >> $sample_delta/added.xml`

`touch $sample_delta/removed.xml`
`echo "<remove-files>" >> $sample_delta/removed.xml`

`touch $sample_delta/delta_info.xml`
`echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" >> $sample_delta/delta_info.xml`
`echo "<delta xmlns=\"http://tizen.org/ns/delta\">" >> $sample_delta/delta_info.xml`

while read line
	do
	count=0
	action="none"
	for word in $line
		do
		count=$((count+1));
		if [ $count -eq 1 ]; then
			 action="only"
		elif [ $count -eq 2 ]; then
			file1=$word;
		elif [ $count -eq 3 ]; then
			file=$word;
		elif [ $count -eq 4 ]; then
			file2=$word;
		elif [ $count -eq 5 ]; then
			action="differ"
		elif [ $count -eq 6 ]; then
			action="same"
		fi
		done
	if [[ "$action" =~ "same" ]]; then
		if [[ "$file2" =~ "config.xml" || "$file2" =~ "tizen-manifest.xml" ]]; then
			parent_path=${file2##*$new_pkg_unzip_path}
			filepath=`basename $parent_path`
			dirpath=`dirname $parent_path`
			if ! mkdir -p $sample_delta$dirpath; then
				echo "FAIL: mkdir failed !" >&2
				cleanup
				exit 1
			fi
			if ! cp -r $new_pkg_unzip_path/$dirpath/$filepath $sample_delta/$dirpath/$filepath; then
				echo "FAIL: cp failed !" >&2
				cleanup
				exit 1
			fi
			dirpath=${dirpath:1:${#dirpath}}
			if [ ${#dirpath} -gt 1 ];then
				dirpath="$dirpath/"
			fi
			`echo "<file name=\"$dirpath$filepath\" />" >> $sample_delta/added.xml`
		fi
	elif [[ "$action" =~ "differ" ]]; then
		parent_path=${file1##*$old_pkg_unzip_path}
		filepath=`basename $parent_path`
		dirpath=`dirname $parent_path`
		#echo "dirpath "$dirpath
		#echo "filepath "$filepath
		if [[ "$file1" =~ "tizen-manifest.xml" || "$file1" =~ "signature1.xml" || "$file1" =~ "author-signature.xml" || "$file1" =~ "config.xml" ]] ; then
			if ! mkdir -p $sample_delta$dirpath; then
				echo "FAIL: mkdir failed !" >&2
				cleanup
				exit 1
			fi
			if ! cp -r $new_pkg_unzip_path/$dirpath/$filepath $sample_delta/$dirpath/$filepath; then
				echo "FAIL: cp failed !" >&2
				cleanup
				exit 1
			fi
		else
			if ! mkdir -p $sample_delta$dirpath; then
				echo "FAIL: mkdir failed!" >&2
				cleanup
				exit 1
			fi
			if ! xdelta3 -e -s $file1 $file2 $sample_delta$dirpath/$filepath; then
				echo "FAIL: xdelta3 failed!" >&2
				cleanup
				exit 1
			fi
		fi

		dirpath=${dirpath:1:${#dirpath}}
		if [ ${#dirpath} -gt 1 ];then
			dirpath="$dirpath/"
		fi
		if [[ "$file1" =~ "tizen-manifest.xml" || "$file1" =~ "signature1.xml" || "$file1" =~ "author-signature.xml" || "$file1" =~ "config.xml" ]] ; then
			`echo "<file name=\"$dirpath$filepath\" />" >> $sample_delta/added.xml`
		else
			`echo "<file name=\"$dirpath$filepath\" />" >> $sample_delta/modified.xml`
		fi

	elif [[ "$action" == "only" && "$file" =~ "$old_pkg_unzip_path" ]]; then
		parent_path=${line##*$old_pkg_unzip_path}
		#echo "removed " $parent_path
		string_to_replace_with="/"
		result_string="${parent_path/: /$string_to_replace_with}"
		#echo $result_string
		dirpath=`dirname $result_string`
		filepath=`basename $result_string`
		#echo "dirpath "$dirpath
		#echo "filepath "$filepath

		dirpath=${dirpath:1:${#dirpath}}
		if [ ${#dirpath} -gt 1 ];then
			dirpath="$dirpath/"
		fi
		`echo "<file name=\"$dirpath$filepath\" />" >> $sample_delta/removed.xml`
	elif [[ "$action" == "only" && "$file" =~ "$new_pkg_unzip_path" ]]; then
		parent_path=${line##*$new_pkg_unzip_path}
		#echo "added " $parent_path
		string_to_replace_with="/"
		result_string="${parent_path/: /$string_to_replace_with}"
		#echo $result_string
		dirpath=`dirname $result_string`
		filepath=`basename $result_string`
		#echo "dirpath "$dirpath
		#echo "filepath "$filepath
		if ! mkdir -p $sample_delta$dirpath; then
			echo "FAIL: mkdir failed!" >&2
			cleanup
			exit 1
		fi
		if ! cp -r $new_pkg_unzip_path/$dirpath/$filepath $sample_delta/$dirpath/$filepath; then
			echo "FAIL: cp failed!" >&2
			cleanup
			exit 1
		fi
		dirpath=${dirpath:1:${#dirpath}}
		if [ ${#dirpath} -gt 1 ];then
			dirpath="$dirpath/"
		fi
		`echo "<file name=\"$dirpath$filepath\" />" >> $sample_delta/added.xml`

	fi
	#echo -e "$line\n";
done < $diff_file

#close tags
`echo "</modify-files>" >> $sample_delta/modified.xml`
`echo "</remove-files>" >> $sample_delta/removed.xml`
`echo "</add-files>" >> $sample_delta/added.xml`

#merge
if ! cat $sample_delta/modified.xml $sample_delta/removed.xml $sample_delta/added.xml >> $sample_delta/delta_info.xml; then
	echo "FAIL: merge failed" >&2
	cleanup
	exit 1
fi
#close tag metadata.xml
`echo "</delta>" >> $sample_delta/delta_info.xml`
#remove temporary xmls
`rm $sample_delta/modified.xml $sample_delta/removed.xml $sample_delta/added.xml `
`chmod -R +x $sample_delta`
cd $sample_delta
dirpath=`dirname $delta_pkg`
#echo $dirpath
filepath=`basename $delta_pkg`
#echo $filepath
`echo zip -r $filepath.zip *`
if ! mv $filepath.zip $dirpath/$filepath.delta; then
	echo "FAIL: mv failed" >&2
	cleanup
	exit 1
fi
`chmod -R +x $dirpath/$filepath.delta`
cd ..

cleanup
