#!/bin/bash

scriptDir="$(dirname "$0")"
. "$scriptDir/watch-sync.sh"

SOURCE=$1
DESTINATION=$2

function camelToHyphen() {
    sed --expression 's/\([A-Z]\)/-\L\1/g' \
    --expression 's/^-//'              \
    <<< "$1"
}

function hyphenToCamel() {
    echo "$1" | awk -F"-" '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1)) substr($i,2)}} 1' OFS=""
}

function installDevExtension() {
    extSrc=$1

    if [[ ! -f "$extSrc/manifest.json" ]]; then
        echo "Manifest for $extSrc is missing!"
        return
    fi

    # get extension name
    extName=$(jq -r .name $extSrc/manifest.json)
    extNameHyphen=$(camelToHyphen "$extName")

    extAppDir="$DESTINATION/application/Espo/Modules/$extName"
    extClientDir="$DESTINATION/client/modules/$extNameHyphen"
    extUploadDir="$DESTINATION/data/uploads/extensions/$extNameHyphen"

    mkdir -p $extAppDir
    mkdir -p $extClientDir
    mkdir -p $extUploadDir

    # copy backend files
    cp -rup "$extSrc/app/." "$extAppDir"
    # copy frontend files
    cp -rup "$extSrc/client/." "$extClientDir"
    # copy scripts
    cp -rup "$extSrc/scripts" "$extUploadDir"
    # copy manifest
    cp -up "$extSrc/manifest.json" "$extUploadDir"

    php $DESTINATION/devextension.php install $extUploadDir
    echo "$extName was installed!"
}

function installZipExtension() {
    extZip=$1

    php $DESTINATION/extension.php $extZip
    echo "$extZip was installed!"
}

function getExtensionName() {
    path=$1
    extPath=${path#"$SOURCE"}
    pathSplit=(${extPath//// })
    echo ${pathSplit[0]}
}

if [[ ! -d "$SOURCE" ]]; then
    echo "Source directory $SOURCE does not exist. Exiting."
    exit
fi

if [[ ! -d "$DESTINATION" ]]; then
    echo "Destination directory $DESTINATION does not exist. Exiting."
    exit
fi

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

inotifywait -r -m $SOURCE -e create,delete,move,close_write |
    while read directory action file; do
        if [[ $file == *".zip" ]]; then
            if [[ $action == "MOVED_TO" ]] || [[ $action == "CREATE" ]]; then
                installZipExtension "${directory}${file}"
            elif [[ $action == "MOVED_FROM" ]] || [[ $aciton == "DELETE" ]]; then
                 echo "Removed extension ${directory}${file}"
            fi
            continue
        fi

        srcPath="${directory}${file}"
        destPath="${srcPath/"$SOURCE"/"$DESTINATION"}"
        destDir="${directory/"$SOURCE"/"$DESTINATION"}"
        extNameHyphen=$(getExtensionName "$srcPath")
        extName=$(hyphenToCamel "$extNameHyphen")

        extSrcAppDir="$SOURCE/$extNameHyphen/app"
        extSrcClientDir="$SOURCE/$extNameHyphen/client"

        extDestAppDir="$DESTINATION/application/Espo/Modules/$extName"
        extDestClientDir="$DESTINATION/client/modules/$extNameHyphen"

        fileDestPath="${srcPath/"$extSrcAppDir"/"$extDestAppDir"}"
        fileDestPath="${fileDestPath/"$extSrcClientDir"/"$extDestClientDir"}"
        #fileDestPath="${fileDestPath/"$SOURCE/$extNameHyphen/manifest.json"/"$DESTINATION/application/Modules/$extName/manifest.json"}"

        if [[ "$srcPath" == "$fileDestPath" ]]; then
            echo "Ignoring $srcPath"
            continue
        fi

        syncWatched $action $srcPath $fileDestPath
    done