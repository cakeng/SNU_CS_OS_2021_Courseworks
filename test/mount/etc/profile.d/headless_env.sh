if [ "$XDG_RUNTIME_DIR" = "" ];
then
export XDG_RUNTIME_DIR=/run
fi

# Ugly workaround to remove "user" filesystem label for two-partition headless images
if [ -e /dev/disk/by-label/user ];
then
e2label /dev/disk/by-label/user ''
fi
