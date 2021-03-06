#!/usr/bin/env bash

# Path to this script
scriptPath=$(dirname $(realpath $0))

# Path to project root
rootPath=$(dirname $(dirname $(dirname $(realpath $0))))

jsonPath="${scriptPath}/optIn.config.json"

# This is to check the optIn.json file whether this dependency has already been added
isAdded=$(cat $jsonPath | jq ".tailwindCSSCRA.added")

# To extract the downloaded file for its github URL
fileNameRegex="([^\/]+$)"

# GitHub urls to raw config file content
configAddresses=($(cat $jsonPath | jq -r ".tailwindCSSCRA.configAddresses[]"))
numberOfConfigs=${#configAddresses[@]}

# Dependencies to install and their numbers
regularDeps=($(cat $jsonPath | jq -r ".tailwindCSSCRA.regularDeps[]"))
regularDepsSize=${#regularDeps[@]}

devDeps=($(cat $jsonPath | jq -r ".tailwindCSSCRA.devDeps[]"))
devDepSize=${#devDeps[@]}

# Whether or not the default TailwindCSS for CRA file has beem generated
useDefaultConfigFile=$(jq ".tailwindCSS.customProperties.useDefaultConfigFile" $jsonPath)

# Script start
if [ "$isAdded" = false ]; then
  echo "Your TailwindCSS configurations have not been added to this project"
  exit
fi

echo "Opting out. Removing TailwindCSS configurations for CRA..."

# Set "tailwindCSS" to false in optIn.json file
echo $(jq '.tailwindCSSCRA.added = false' $jsonPath) >$jsonPath
echo "Uninstalling packages"

installationStatus="Uninstallation successful"

# Since it is the same command to remove regular and dev dependencies, merge them and remove them all
allDeps=("${devDeps[@]}" "${regularDeps[@]}")

if [ ${#allDeps[@]} -gt 0 ]; then
  npm un ${allDeps[@]}
else
  installationStatus="No Packages to uninstall"
fi

echo "${installationStatus}. Remvoing configs.."

if [ $numberOfConfigs -gt 0 ]; then

  for address in ${configAddresses[@]}; do
    [ "$useDefaultConfigFile" = true ] && [[ "$address" = *tailwind* ]] && continue

    # Extract the filename from its url
    fileName=$(echo $address | grep -oE $fileNameRegex)
    rm "${rootPath}/${fileName}"
  done
  echo "Config files removed"
else
  echo "No configs to remove"
fi

# Resetting package.json scripts
echo $(jq '.scripts.start = "react-scripts start"' "${rootPath}/package.json") >$rootPath/package.json
echo $(jq '.scripts.build = "react-scripts build"' "${rootPath}/package.json") >$rootPath/package.json
echo $(jq '.scripts.test = "react-scripts test"' "${rootPath}/package.json") >$rootPath/package.json

echo "Removing tailwind.js and tailwind.css"
[ "$useDefaultConfigFile" = false ] && rm "${rootPath}/tailwind.js"

rm "${rootPath}/src/tailwind.css"

echo "Removing TailwindCSS import statement from index.js"
tailwindImportLineNumber=$(grep -Rn "import './tailwind.css'" "${rootPath}/src/index.js" | grep -oE '[0-9]+')
sed -i "${tailwindImportLineNumber}d" "${rootPath}/src/index.js"

echo "Opt out complete"
