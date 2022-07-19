# Synchronizes changes to a watched directory (inotify)
# into destionation.
function syncWatched() {
    action=$1
    src=$2
    dest=$3

    case $action in
        "CREATE"|"CLOSE_WRITE,CLOSE"|"MOVED_TO")
            mkdir -p "$(dirname $dest)"
            cp -fup "$src" "$dest"
            echo "Updated $dest from $src"
            ;;
        "MOVED_FROM"|"DELETE")
            rm -f "$dest"
            echo "Deleted $dest"
            ;;
        "CREATE,ISDIR"|"MOVED_TO,ISDIR")
            mkdir -p "$(dirname $dest)"
            cp -rup "$src/." "$dest"
            echo "Updated $dest from $src"
            ;;
        "MOVED_FROM,ISDIR"|"DELETE,ISDIR")
            rm -rf "$dest"
            echo "Deleted $dest"
            ;;
    esac
}