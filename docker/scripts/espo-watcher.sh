#!/bin/bash

: '
Starts a watcher on SOURCE directory (espocrm installation) and will merge
    changes into DESTINATION, preserving EspoCRM file structure.

Syntax:
   espo-watcher.sh <SOURCE> <DESTINATION>
'

scriptDir="$(dirname "$0")"
. "$scriptDir/watch-sync.sh"

SOURCE=$1
DESTINATION=$2

# watch for changes in SOURCE directory
inotifywait -r -m "$SOURCE" -e create,close_write,move,delete |
    while read directory action file; do
        path="${directory}${file}"
        dest="${path/"$SOURCE"/"$DESTINATION"}"

        # sync files to destination
        syncWatched $action $path $dest
    done
