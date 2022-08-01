#!/bin/bash

: '
Starts a watcher on SOURCE (directory containing espocrm extensions)
and merges changes into DESTINATION (espocrm installation).

The script will handle installation and update of extensions.

Syntax:
    ext-watcher.sh <SOURCE> <DESTINATION>
'
scriptDir="$(dirname "$0")"
. "$scriptDir/watch-sync.sh"

SOURCE=$1
DESTINATION=$2

# convert CamelCase to hyphen-case
function camelToHyphen() {
    sed --expression 's/\([A-Z]\)/-\L\1/g' \
    --expression 's/^-//'              \
    <<< "$1"
}

# convert hyphen-case to CamelCase
function hyphenToCamel() {
    echo "$1" | awk -F"-" '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1)) substr($i,2)}} 1' OFS=""
}

# install extension from source (initialized with superewald/espo-extension-template)
function installDevExtension() {
    extSrc=$1

    # validate that directory contains manifest
    if [[ ! -f "$extSrc/extension.json" ]]; then
        echo "ERROR: Extension $extSrc has no extension.json"
        return
    fi

    # get extension name
    extConfig="$extSrc/extension.json"
    extName=$(jq -r .module "$extConfig")
    extNameHyphen=$(camelToHyphen "$extName")

    # match files from template to espo structure
    extAppDir="$DESTINATION/application/Espo/Modules/$extName"
    extClientDir="$DESTINATION/client/modules/$extNameHyphen"
    extUploadDir="$DESTINATION/data/upload/extensions/$extNameHyphen"
    extScriptDir="$extUploadDir/scripts"

    if [[ -d "$extSrc/app" ]]; then
        extSrcAppDir="$extSrc/app"
        extSrcClientDir="$extSrc/client"
        extSrcScriptDir="$extSrc/scripts"
    elif [[ -d "$extSrc/src/files" ]]; then
        extSrcAppDir="$extSrc/src/files/application/Espo/Modules/$extName"
        extSrcClientDir="$extSrc/src/files/client/modules/$extNameHyphen"
        extSrcScriptDir="$extSrc/src/scripts"
    fi

    # create necessary directories
    mkdir -p $extAppDir
    mkdir -p $extClientDir
    mkdir -p $extScriptDir

    # copy backend files
    cp -rup "$extSrcAppDir/." "$extAppDir"
    # copy frontend files
    cp -rup "$extSrcClientDir/." "$extClientDir"
    # copy scripts
    cp -rup "$extSrcScriptDir/." "$extScriptDir"
    # copy extension.json
    cp -up "$extSrc/extension.json" "$extUploadDir/manifest.json"
    # move composer files
    if [[ -d "$extSrc/vendor" ]]; then
        mkdir -p "$extAppDir/vendor"
        cp -rup "$extSrc/vendor/." "$extAppDir/vendor"
    fi

    # install extension in espocrm
    php $DESTINATION/devextension.php install $extUploadDir
    echo "$extName was installed!"
}

# install extension from zip archive
function installZipExtension() {
    extZip=$1

    # run extension installer for zip archives (standard)
    php $DESTINATION/extension.php $extZip
    echo "$extZip was installed!"
}

function getExtensionBaseDir() {
    path=$1
    extPath=${path#"$SOURCE"}
    extPath=(${extPath//// })
    extPath=${extPath[0]}
    echo "$SOURCE/$extPath"
}

function isEspoInstalled() {
    path=$1

    if [[ -f "$path/data/config-internal.php" ]]; then
        if grep -Fq "'isInstalled' => true" "$path/data/config-internal.php"; then
            return 0
        fi
    fi

    return 1
}

# validate arguments
if [[ ! -d "$SOURCE" ]]; then
    echo "Source directory $SOURCE does not exist. Exiting."
    exit
elif [[ ! -d "$DESTINATION" ]]; then
    echo "Destination directory $DESTINATION does not exist. Exiting."
    exit
fi

# copy custom extension installer for superewald's template
cp -up "/home/espo/scripts/devextension.php" "$DESTINATION/devextension.php"

# wait until EspoCRM has been installed
while ! isEspoInstalled "$DESTINATION"; do
    sleep 5
done

# find all zip files containing extensions and install them
for zip in `find $SOURCE -maxdepth 1 -type f -name '*.zip'`; do 
    installZipExtension "$zip"
done

# find all local extension repos and install them
for dir in `find $SOURCE -maxdepth 1 -mindepth 1 -type d`; do
    if [[ -d "$dir" ]]; then
        installDevExtension $dir
    fi
done

# watch for changes in SOURCE 
inotifywait -r -m $SOURCE -e create,delete,move,close_write |
    while read directory action file; do
        # if file is zip archive un/install it
        if [[ $file == *".zip" ]]; then
            if [[ $action == "MOVED_TO" ]] || [[ $action == "CREATE" ]]; then
                installZipExtension "${directory}${file}"
            elif [[ $action == "MOVED_FROM" ]] || [[ $aciton == "DELETE" ]]; then
                # TODO: uninstall zip extension from espocrm
                 echo "Removed extension ${directory}${file}"
            fi
            continue
        fi

        # extension source/destination
        srcPath="${directory}${file}"
        destPath="${srcPath/"$SOURCE"/"$DESTINATION"}"
        destDir="${directory/"$SOURCE"/"$DESTINATION"}"

        # extension name
        extSrcDir=$(getExtensionBaseDir "$directory")
        extName=$(jq -r .module "$extSrcDir/extension.json")
        extNameHyphen=$(camelToHyphen "$extNameHyphen")

        if [[ ! -d "$extSrcDir/src/files" ]]; then 
            # directories that trigger a change to the extension
            extSrcAppDir="$extSrcDir/app"
            extSrcClientDir="$extSrcDir/client"
            extSrcScriptDir="$extSrcDir/scripts"
        else
            extSrcAppDir="$extSrcDir/src/files/application/Espo/Modules/$extName"
            extSrcClientDir="$extSrcDir/src/files/client/modules/$extNameHyphen"
            extSrcScriptDir="$extSrcDir/src/scripts"
        fi
        extSrcVendorDir="$extSrcAppDir/vendor"

        # matching destinations
        extDestAppDir="$DESTINATION/application/Espo/Modules/$extName"
        extDestVendorDir="$extDestAppDir/vendor"
        extDestClientDir="$DESTINATION/client/modules/$extNameHyphen"
        extDestUploadDir="$DESTINATION/data/upload/extensions/$extNameHyphen"
        extDestScriptDir="$extDestUploadDir/scripts"

        # replace directory paths
        fileDestPath="${srcPath/"$extSrcAppDir"/"$extDestAppDir"}"
        fileDestPath="${fileDestPath/"$extSrcClientDir"/"$extDestClientDir"}"
        fileDestPath="${fileDestPath/"$extSrcScriptDir"/"$extDestScriptDir"}"
        fileDestPath="${fileDestPath/"$extSrcVendorDir"/"$extDestVendorDir"}"

        # if script path handle installation
        if [[ "$fileDestPath" == *"$extDestScriptDir"* ]]; then 
            echo "Update extension..."
            php $DESTINATION/devextension.php uninstall $extDestUploadDir

            cp -rup "$extSrcScriptDir/." "$extDestScriptDir"

            php $DESTINATION/devextension.php install $extDestUploadDir
            echo "Extension was updated!"
            continue
        elif [[ "$srcPath" == "$extSrcVendorDir"* ]]; then
            cp -rup "$extSrcVendorDir/." "$extDestVendorDir"
        fi 

        # skip if file/path is ignored
        if [[ "$srcPath" == "$fileDestPath" ]]; then
            echo "Ignoring $srcPath"
            continue
        fi

        # synchronize extension files
        syncWatched $action $srcPath $fileDestPath

        if [[ "$srcPath" == *"$extSrcAppDir/Resources/"* ]]; then
            echo "Rebuild EspoCRM..."
            php $DESTINATION/bin/command clear-cache
            php $DESTINATION/bin/command rebuild
            echo "EspoCRM has been rebuild!"
        elif [[ "$srcPath" == *"$extSrcClientDir/"* ]]; then
            php $DESTINATION/bin/command clear-cache
        fi
    done