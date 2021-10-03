#!/bin/sh

CP="/bin/cp"
LN="/bin/ln"
SED="/bin/sed"
MKDIR="/bin/mkdir"
PARTX="/usr/sbin/partx"
BLKID="/usr/sbin/blkid"
DIRNAME="/usr/bin/dirname"
MKDIR="/bin/mkdir"
LD_LINUX="/lib/ld-linux.so.3"
RM="/bin/rm"
TR="/bin/tr"
GREP="/bin/grep"
CUT="/bin/cut"

INITRD_ROOT="/mnt/initrd-recovery"

OBJECTS_SPECIFY_DIR="/usr/share/initrd-recovery/initrd.list.d"
OBJECTS_DIRECTORY=
OBJECTS_VERBATIM=
OBJECTS_WITHLIB=
OBJECTS_LIBONLY=
OBJECTS_SYMLINK=
OBJECTS_MVWITHLIB=

BASE_DIRECTORIES="
/dev
/etc
/proc
/sdcard
/smack
/sys
/system
/system-ro
/run
/tmp
/usr/bin
/usr/sbin
/usr/lib
/var/log
"

BASE_DIR_SYMLINKS="
/bin:usr/bin
/sbin:usr/sbin
/lib:usr/lib
/opt:system/opt
"

OPT="default"

#-----------------------------------------------------------------------------
#       help
#-----------------------------------------------------------------------------
show_help() {
    echo
    echo "usage: `basename $0` [OPTION]"
    echo "make initrd image"
    echo
    echo "  -h, --help          show help"
    echo "  -p, --post          find initrd partition and format and make"
    echo "                       initrd image to there"
    echo
}

#-----------------------------------------------------------------------------
#       find initrd-recovery partition
#-----------------------------------------------------------------------------
find_initrd_recovery_partition() {
    EMMC_DEVICE="/dev/mmcblk0"
    RET_PARTX=$("$PARTX" -s ${EMMC_DEVICE})
    TEST=$(echo "$RET_PARTX" | "$TR" -s ' ' | "$SED" -e '1d' -e 's/^ //' | "$CUT" -d ' ' -f 6)
    if [ "z$TEST" == "z" ]; then
        PART_INITRD=$("$BLKID" -L "ramdisk-recovery" -o device)
        if [ "z$PART_INITRD" == "z" ]; then
            PART_INITRD=$("$BLKID" -L "ramdisk" -o device)
        fi
    else
        PART_INITRD=${EMMC_DEVICE}p$(
            echo "$RET_PARTX" |
            "$TR" -s ' ' | "$TR" '[:upper:]' '[:lower:]' |
            "$GREP" "ramdisk2" | "$SED" 's/^ //' | "$CUT" -d ' ' -f 1)
        if [ "z$PART_INITRD" == "z/dev/mmcblk0p" ]; then
            PART_INITRD=${EMMC_DEVICE}p$(
                echo "$RET_PARTX" |
                "$TR" -s ' ' | "$TR" '[:upper:]' '[:lower:]' |
                "$GREP" "ramdisk" | "$SED" 's/^ //' | "$CUT" -d ' ' -f 1)
        fi
    fi
}

#-----------------------------------------------------------------------------
#       Prepare parent directory
#-----------------------------------------------------------------------------
mkdir_p_parent() {
    dst_dir=`"$DIRNAME" "$1"`
    if [ ! -d "$dst_dir" -a ! -L "$dst_dir" ]; then
        "$MKDIR" -p "$dst_dir"
    fi
}

#-----------------------------------------------------------------------------
#       Copy content to root of mounted image
#-----------------------------------------------------------------------------
do_copy() {
    src=$1
    dst="$INITRD_ROOT/$src"

    if [ ! -e "$src" -o -e "$dst" ]; then
        return
    fi

    mkdir_p_parent $dst

    "$CP" -f "$src" "$dst"
}

#-----------------------------------------------------------------------------
#       Get dependency libraries
#-----------------------------------------------------------------------------
get_dep_libs() {
    "$LD_LINUX" --list $1 | "$SED" -r 's|^[^/]+([^ \(]+).*$|\1|'
}

#-----------------------------------------------------------------------------
#       Gather initrd objects
#-----------------------------------------------------------------------------
get_initrd_objects() {
    for f in $(ls ${OBJECTS_SPECIFY_DIR}); do
        DIRECTORIES=
        DIR_SYMLINKS=
        VERBATIMS=
        WITHLIBS=
        LIBONLYS=
        SYMLINKS=
        MVWITHLIBS=
        source "${OBJECTS_SPECIFY_DIR}"/$f
        OBJECTS_DIRECTORY="$OBJECTS_DIRECTORY $DIRECTORIES"
        OBJECTS_DIR_SYMLINK="$OBJECTS_DIR_SYMLINK $DIR_SYMLINKS"
        OBJECTS_VERBATIM="$OBJECTS_VERBATIM $VERBATIMS"
        OBJECTS_WITHLIB="$OBJECTS_WITHLIB $WITHLIBS"
        OBJECTS_LIBONLY="$OBJECTS_LIBONLY $LIBONLYS"
        OBJECTS_SYMLINK="$OBJECTS_SYMLINK $SYMLINKS"
        OBJECTS_MVWITHLIB="$OBJECTS_MVWITHLIB $MVWITHLIBS"
    done

    OBJECTS_DIRECTORY=$(echo "$OBJECTS_DIRECTORY" | sort | uniq)
    OBJECTS_DIR_SYMLINK=$(echo "$OBJECTS_DIR_SYMLINK" | sort | uniq)
    OBJECTS_VERBATIM=$(echo "$OBJECTS_VERBATIM" | sort | uniq)
    OBJECTS_WITHLIB=$(echo "$OBJECTS_WITHLIB" | sort | uniq)
    OBJECTS_LIBONLY=$(echo "$OBJECTS_LIBONLY" | sort | uniq)
    OBJECTS_SYMLINK=$(echo "$OBJECTS_SYMLINK" | sort | uniq)
    OBJECTS_MVWITHLIB=$(echo "$OBJECTS_MVWITHLIB" | sort | uniq)
}

#-----------------------------------------------------------------------------
#       Prepare directory objects
#-----------------------------------------------------------------------------
prepare_directory_objects() {
    for dir in $@; do
        "$MKDIR" -p "$INITRD_ROOT$dir"
    done
}

#-----------------------------------------------------------------------------
#       Copy verbatim objects
#-----------------------------------------------------------------------------
verbatim_objects() {
    for obj in $@; do
        do_copy $obj
    done
}

#-----------------------------------------------------------------------------
#       Copy withlib objects
#-----------------------------------------------------------------------------
withlib_objects() {
    for content in $@; do
        do_copy $content

        DEP_LIBS=$(get_dep_libs $content)
        for lib in $DEP_LIBS; do
            do_copy $lib
        done
    done
}

mvwithlib_objects() {
    for content in $@; do

        do_copy $content

        "$LD_LINUX" --verify $content
        if [ $? -eq 0 ]; then
            DEP_LIBS=$(get_dep_libs $content)
            for lib in $DEP_LIBS; do
                do_copy $lib
            done
        fi

        "$RM" -rf $content
    done
}

#-----------------------------------------------------------------------------
#       Copy libonly objects
#-----------------------------------------------------------------------------
libonly_objects() {
    for content in $@; do
        DEP_LIBS=$(get_dep_libs $content)
        for lib in $DEP_LIBS; do
            do_copy $lib
        done
    done
}

#-----------------------------------------------------------------------------
#       Copy symlink objects
#-----------------------------------------------------------------------------
symlink_objects() {
    for i in $@; do
        if [ "z$i" == "z" ]; then
            continue
        fi

        link=${i%:*}
        target=${i#*:}
        mkdir_p_parent "$INITRD_ROOT$link"
        "$LN" -s "$target" "$INITRD_ROOT$link"
    done
}

#-----------------------------------------------------------------------------
#       Copy content
#-----------------------------------------------------------------------------
make_initrd_recovery() {
    echo "copy initrd objects to $INITRD_ROOT"
    get_initrd_objects

    prepare_directory_objects $BASE_DIRECTORIES
    symlink_objects $BASE_DIR_SYMLINKS
    prepare_directory_objects $OBJECTS_DIRECTORY
    symlink_objects $OBJECTS_DIR_SYMLINK
    verbatim_objects $OBJECTS_VERBATIM
    withlib_objects $OBJECTS_WITHLIB
    libonly_objects $OBJECTS_LIBONLY
    symlink_objects $OBJECTS_SYMLINK
    mvwithlib_objects $OBJECTS_MVWITHLIB
}

#-----------------------------------------------------------------------------
#       Check given parameter is mount point
#-----------------------------------------------------------------------------
check_mount_point() {
    grep " $1 " /etc/mtab > /dev/null
    if [ $? -ne 0 ]; then
        echo "$1 is not mount point"
        exit 0
    fi
}

#-----------------------------------------------------------------------------
#       Main
#-----------------------------------------------------------------------------
ARGS=$(getopt -o hp -l "help,post" -n "$0" -- "$@");

eval set -- "$ARGS";

while true; do
    case "$1" in
        -h|--help)
            show_help >&2
            exit 0
            ;;
        -p|--post)
            OPT="post"
            shift
            ;;
        --)
            shift;
            break;
            ;;
    esac
done

if [ $# -gt 1 ]; then
    echo "Error: too many argument was given."
    show_help >&2
    exit 1
fi

case $OPT in
    post)
        find_initrd_recovery_partition
        if [ "z$PART_INITRD" == "z/dev/mmcblk0p" ]; then
            echo "Error: failed to find initrd partition"
            exit 1
        else
            echo "Info: initrd partition: $PART_INITRD"
        fi
        mke2fs $PART_INITRD
        e2fsck $PART_INITRD
        mount $PART_INITRD $INITRD_ROOT
        make_initrd_recovery
        umount $INITRD_ROOT
        ;;
    *)
        check_mount_point $INITRD_ROOT
        make_initrd_recovery
        ;;
esac
