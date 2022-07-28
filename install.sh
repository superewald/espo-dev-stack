#!/bin/bash

echo "<< Installer for EspoCRM development containers >>"
echo ""

read -p "=> Chose install directory [./espodev]: " installDir
installDir=${installDir:-"./espodev"}

# create install dir if not exist
if [[ -d "$installDir" ]]; then 
    mkdir -p "$installDir"
fi

read -p "=> Chose EspoCRM git repository url [https://github.com/espocrm/espocrm]: " espoRepoUrl
espoRepoUrl=${espoRepoUrl:-"https://github.com/espocrm/espocrm"}

echo "=> Install espocrm stack to $installDir <="
# clone espocrm repository to ./espocrm
git clone "$espoRepoUrl" "$installDir/espocrm"
# clone dev stack to ./stack
git clone https://github.com/superewald/espo-dev-stack "$installDir/stack"
# create comfort symlink to ./stack/compose
ln -s "$installDir/stack/compose" "$installDir/compose"

echo ""
echo "=> Build espocrm container <="
"$installDir/compose" build

echo ""
echo "=> Chose extensions to install (must be git repo or zip; empty to skip):"
mkdir -p "$installDir/extensions"
prevCwd=$(pwd)
cd "$installDir/extensions"
while true; do
    read -p "=> Extension: " ext
    
    # if input is empty break while
    if [[ "$ext" == "" ]]; then
        break
    fi

    if [[ "$ext" == *".zip" ]]; then
        # copy zip folder to extension directory (the container will handle installation)
        cp -p "$ext" "$installDir/extensions/"
    else
        # clone extension
        git clone "$ext"
    fi

    echo ""
done
cd "$prevCwd"

echo "=> Configure VSCode <="
mkdir -p "$installDir/.vscode"

# vscode configuration
echo '{
    "git.repositoryScanMaxDepth": 5,
    "php.suggest.basic": false
}' > "$installDir/.vscode/settings.json"

echo "=> Build EspoCRM <="
prevCwd=$(pwd)
cd "$installDir/espocrm"
# install composer and npm deps
composer install
npm install
# build espocrm frontend files
npx grunt offline
cd "$prevCwd"

echo ""
echo ""
echo "The EspoCRM developer stack has been installed to $installDir!"
echo "You can start the containers by running './compose up -d' from $installDir"
