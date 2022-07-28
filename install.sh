#!/bin/bash

read -p "=> Chose install directory [./espodev]: " installDir
installDir=${installDir:-"./espodev"}


read -p "=> Chose EspoCRM git repository url [https://github.com/espocrm/espocrm]: " espoRepoUrl
espoRepoUrl=${espoRepoUrl:-"https://github.com/espocrm/espocrm"}

if [[ -d "$installDir" ]]; then 
    mkdir -p "$installDir"
fi

echo "=> Install espocrm stack to $installDir <="
git clone "$espoRepoUrl" "$installDir/espocrm"
git clone https://github.com/superewald/espo-dev-stack "$installDir/stack"

echo "=> Build espocrm container <="
"$installDir/stack/compose" build


echo "=> Chose extensions to install (must be git repo or zip; empty to skip):"
mkdir -p "$installDir/extensions"
prevCwd=$(pwd)
cd "$installDir/extensions"
while true; do
    read -p "Extension: " ext
    
    if [[ "$ext" == "" ]]; then
        break
    fi

    if [[ "$ext" == *".zip" ]]; then
        cp -p "$ext" "$installDir/extensions/"
    else
        git clone "$ext"
    fi
done
cd "$prevCwd"

echo "=> Configure VSCode <="
mkdir -p "$installDir/.vscode"

echo '{
    "git.repositoryScanMaxDepth": 5,
    "php.suggest.basic": false
}' > "$installDir/.vscode/settings.json"

echo "=> Build EspoCRM <="
prevCwd=$(pwd)
cd "$installDir/espocrm"
composer install
npm install
npx grunt offline

echo ""
echo ""
echo "The EspoCRM developer stack has been installed to $installDir!"
echo "You can start the containers by running `./stack/compose up -d` from $installDir"
