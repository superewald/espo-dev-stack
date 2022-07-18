#!/bin/bash

SOURCE=./espocrm
DESTINATION=./espodev

# check if source exist
if [[ ! -d "$SOURCE" ]]; then
    echo "Source directory $SOURCE does not exist! Exiting.."
fi

# create destination dir if not exist
if [[ ! -d "$DESTINATION" ]]; then
    mkdir -p $DESTINATION
fi

cp -ru "$SOURCE/." "$DESTINATION"

inotifywait -r -m ./espocrm -e create,close_write,move,delete |
    while read directory action file; do
        srcPath="${directory}${file}"
        destPath="${srcPath/"$SOURCE"/"$DESTINATION"}"
        
        case $action in
            "CREATE")
                mkdir -p "$destPath"
                cp -f "$srcPath" "$destPath"
                echo "Created $destPath"
                ;;
            "CLOSE_WRITE,CLOSE")
                mkdir -p "$destPath"
                cp -f "$srcPath" "$destPath"
                echo "Modified $destPath"
                ;;
            "MOVED_TO")
                mkdir -p "$destPath"
                cp -f "$srcPath" "$destPath"
                echo "Moved to $destPath"
                ;;
            "MOVED_FROM")
                rm -f "$destPath"
                echo "Deleted $destPath"
                ;;
            "DELETE")
                rm -f "$destPath"
                echo "Deleted $destPath"
                ;;
        esac
    done
