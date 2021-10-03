#!/bin/bash
#
# update-helper.sh
#

UPDATE_PACKAGE=$1
PACKAGE_DIR=$(dirname ${UPDATE_PACKAGE})

if [ ! -d "${PACKAGE_DIR}" ]; then
	echo "Error: Invalid update package directory: ${PACKAGE_DIR}"
fi

if [ ! -e "${UPDATE_PACKAGE}" ]; then
	echo "Error: The update package does not exist: ${UPDATE_PACKAGE}"
fi

# Decompress update package (delta.tar.gz -> delta.tar)
echo "Decompress update package"
gzip -d ${UPDATE_PACKAGE}
UPDATE_PACKAGE=${UPDATE_PACKAGE%.*}

echo "Pass the update package to trigger"
echo "update package: ${UPDATE_PACKAGE}"

tar xvfp ${UPDATE_PACKAGE} -C ${PACKAGE_DIR} upgrade-trigger.sh
exec ${PACKAGE_DIR}/upgrade-trigger.sh ${UPDATE_PACKAGE}
