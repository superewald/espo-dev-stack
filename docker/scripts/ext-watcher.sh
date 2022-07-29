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

function createExtensionManifest() {
    extSrc=$1

    php $DESTINATION/devextension.php buildManifest
}

# install extension from source (initialized with superewald/espo-extension-template)
function installDevExtension() {
    extSrc=$1
    extConfig="$extSrc/extension.json"

    # validate that directory contains manifest
    extConfig=$(getExtensionConfigFile "$extSrc")
    if [[ "$extConfig" == "" ]]; then
        echo "ERROR: Extension $extSrc has no manifest.json or extension.json"
        return
    fi

    # get extension name
    extName=$(jq -r .module $extConfig)
    extNameHyphen=$(camelToHyphen "$extName")

    # match files from template to espo structure
    extAppDir="$DESTINATION/application/Espo/Modules/$extName"
    extClientDir="$DESTINATION/client/modules/$extNameHyphen"

    if [[ -d "$extSrc/app" ]]; then
        extSrcAppDir="$extSrc/app"
        extSrcClientDir="$extSrc/client"
    elif [[ -d "$extSrc/src/files" ]]; then
        extSrcAppDir="$extSrc/src/files/application/Espo/Modules/$extName"
        extSrcClientDir="$extSrc/src/files/client/modules/$extNameHyphen"
    fi

    # create necessary directories
    mkdir -p $extAppDir
    mkdir -p $extClientDir

    # copy backend files
    cp -rup "$extSrcAppDir/." "$extAppDir"
    # copy frontend files
    cp -rup "$extSrcClientDir/." "$extClientDir"

    # install extension in espocrm
    php $DESTINATION/devextension.php install $extSrc
    echo "$extName was installed!"
}

# install extension from zip archive
function installZipExtension() {
    extZip=$1

    # run extension installer for zip archives (standard)
    php $DESTINATION/extension.php $extZip
    echo "$extZip was installed!"
}

# get extension name from path
function getExtensionName() {
    path=$1
    extPath=${path#"$SOURCE"}
    pathSplit=(${extPath//// })
    echo ${pathSplit[0]}
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

        if [[ ! -f "$directory/extension.json" ]]; then
            echo "Error: Extension file for $directory is missing!"
            continue
        fi

        # extension name
        extNameHyphen=$(jq -r .module "$directory/extension.json")
        extName=$(hyphenToCamel "$extNameHyphen")
        extSrcDir="$SOURCE/$extNameHyphen"

        if [[ ! -d "$extSrcDir/src/files" ]]; then 
            # directories that trigger a change to the extension
            extSrcAppDir="$extSrcDir/app"
            extSrcClientDir="$extSrcDir/client"
            extSrcScriptDir="$extSrcDir/scripts"
        else
            extSrcAppDir="$extSourceDir/src/files/application/Espo/Modules/$extName"
            extSrcClientDir="$extSourceDir/src/files/client/modules/$extNameHyphen"
            extSrcScriptDir="$extSourceDir/src/scripts"
        fi

        # matching destinations
        extDestAppDir="$DESTINATION/application/Espo/Modules/$extName"
        extDestClientDir="$DESTINATION/client/modules/$extNameHyphen"
        extDestScriptDir="$DESTIONATION/data/uploads/extensions/$extNameHyphen/scripts"

        # replace directory paths
        fileDestPath="${srcPath/"$extSrcAppDir"/"$extDestAppDir"}"
        fileDestPath="${fileDestPath/"$extSrcClientDir"/"$extDestClientDir"}"
        fileDestPath="${fileDestPath/"$extSrcScriptDir"/"$extDestScriptDir"}"

        # if script path handle installation
        if [[ "$fileDestPath" == *"$extDestScriptDir" ]]; then 
            php $DESTINATION/devextension.php uninstall $extSrc

            cp -rup "$extSrcScriptDir/." "$extDestScriptDir"

            php $DESTINATION/devextension.php install $extSrc
            continue
        fi 
        # skip if file/path is ignored
        if [[ "$srcPath" == "$fileDestPath" ]]; then
            echo "Ignoring $srcPath"
            continue
        fi

        # synchronize extension files
        syncWatched $action $srcPath $fileDestPath
    done