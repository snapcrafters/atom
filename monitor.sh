#!/usr/bin/env bash

# This script requires:
#     apt install jq curl git

PROJECT=atom
REPO=atom
TYPE=amd64.deb

if [ -f OLD_VERSION ]; then
    source OLD_VERSION
else
    OLD_VERSION=0
fi
REBUILD=0
JSON=${PROJECT}-${REPO}.json

# Get the latest releases json
curl -s https://api.github.com/repos/${PROJECT}/${REPO}/releases/latest > "${JSON}"

# Get the version from the tag_name and the download URL.
VERSION=$(jq . "${JSON}" | grep tag_name | cut -d'"' -f4 | sed 's/v//')
DEB_URL=$(cat "${JSON}" | jq -r ".assets[] | select(.name | test(\"${TYPE}\")) | .browser_download_url")
DEB=$(basename "${DEB_URL}")
rm -f "${JSON}" 2>/dev/null
rm -f snap/snapcraft.yaml.new 2>/dev/null

if [ "${OLD_VERSION}" != "${VERSION}" ]; then
    echo "Detected ${VERSION}, which is different from ${OLD_VERSION}!"
    sed "s/VVV/${VERSION}/" snap/snapcraft.yaml.in > snap/snapcraft.yaml.new
    sed -i "s|UUU|${DEB_URL}|" snap/snapcraft.yaml.new
    REBUILD=1
else
    echo "No version change, still ${OLD_VERSION}. Stopping here."
fi

if [ ${REBUILD} -eq 1 ]; then
    mv snap/snapcraft.yaml.new snap/snapcraft.yaml
    echo "OLD_VERSION=${VERSION}" > OLD_VERSION
fi
