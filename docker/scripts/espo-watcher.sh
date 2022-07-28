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

        # sync files to destination
        syncWatched $action $path $dest

        if [[ "$directory" == *"application/Espo/Resources/"* ]]; then
            # rebuild cache
            echo "Clearing cache and rebuilding.. "
            php "$SOURCE/bin/command clear-cache"
            php "$SOURCE/bin/command rebuild"
        elif [[ "$directory" == *"client/src/"* ]]; then
            echo "Building frontend library.."
            prevCwd=$(pwd)
            cd "$SOURCE"
            npx grunt espo-bundle
            npx grunt prepare-lib-original
            npx grunt uglify:bundle
            cd "$prevCwd"
        elif [[ "$directory" == *"frontend/less/"* ]]; then
            # build frontend css
            echo "Building frontend css.."
            npx grunt less
            npx grunt cssmin
        fi

    done
