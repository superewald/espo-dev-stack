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

echo "Started EspoCRM watcher on $SOURCE directory!"

# watch for changes in SOURCE directory
inotifywait -r -m "$SOURCE" -e create,close_write,move,delete |
    while read directory action file; do
        path="${directory}${file}"
        dest="${path/"$SOURCE"/"$DESTINATION"}"
        
        if [[ "$directory" == *".git/"* ]]; then
            continue
        fi

        # sync files to destination
        syncWatched $action $path $dest

        if [[ "$directory" == *"application/Espo/Resources/"* ]]; then
            # rebuild cache
            echo "Clearing cache and rebuilding.. "
            php "$DESTINATION/bin/command clear-cache"
            php "$DESTINATION/bin/command rebuild"
        elif [[ "$directory" == *"client/src/"* ]]; then
            echo "Building frontend library.."
            npx grunt --base "$DESTINATION" espo-bundle
            npx grunt --base "$DESTINATION" prepare-lib-original
            npx grunt --base "$DESTINATION" uglify:bundle
        elif [[ "$directory" == *"frontend/less/"* ]]; then
            # build frontend css
            echo "Building frontend css.."
            npx grunt --base "$DESTINATION" less
            npx grunt --base "$DESTINATION" cssmin
        fi

    done
