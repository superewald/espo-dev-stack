#!/bin/bash

: '
Synchronizes <SOURCE> (espocrm installation) into <DESTINATION>
and handles installation and update of <EXTENSIONS> into <DESTINATION>

Syntax:
    init-watcher.sh <SOURCE> <EXTENSIONS> <DESTINATION>
'

scriptDir="$(dirname "$0")"

ESPO_SOURCE=$1
EXT_SOURCE=$2
ESPO_DEST=$3

# validate arguments
if [[ ! -d "$ESPO_SOURCE" ]]; then
    echo "EspoCRM source directory does not exist at $ESPO_SOURCE! Exit."
    exit
elif [[ ! -d "$EXT_SOURCE" ]]; then
    echo "Extension source directory does not exist at $EXT_SOURCE! Exit."
    exit
elif [[ ! -d "$ESPO_DEST" ]]; then
    mkdir -p "$ESPO_DEST"
fi

# synchronize espo source
cp -rup "$ESPO_SOURCE/." "$ESPO_DEST"

# start watchers
"$scriptDir/espo-watcher.sh" "$ESPO_SOURCE" "$ESPO_DEST" &
"$scriptDir/ext-watcher.sh" "$EXT_SOURCE" "$ESPO_DEST"