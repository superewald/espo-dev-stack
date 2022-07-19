#!/bin/bash

scriptDir="$(dirname "$0")"
. "$scriptDir/watch-sync.sh"

SOURCE=$1
DESTINATION=$2

inotifywait -r -m "$SOURCE" -e create,close_write,move,delete |
    while read directory action file; do
        path="${directory}${file}"

        # if notify comes from destination directory
        if [[ $directory == "$DESTINATION"* ]]; then
            dest="${path/"$DESTINATION"/"$SOURCE"}"

            # only sync /data,/custom and /client/custom to source
            if [[ $directory == "$DESTINATION/data/"* ]] || [[ $directory == "$DESTINATION/custom/"* ]] || [[ $directory == "$DESTINATION/client/custom/"* ]]; then
                syncWatched $action $path $dest
                continue
            fi
        # if notify comes from source directory
        elif [[ $directory == "$SOURCE"* ]]; then
            dest="${path/"$SOURCE"/"$DESTINATION"}"

            # sync files to destination
            syncWatched $action $path $dest
            continue
        fi
    done
