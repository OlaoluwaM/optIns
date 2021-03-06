#!/usr/bin/env bash

# Path to this script
scriptDirPath=$(dirname $(dirname $(realpath $0)))

# Path to project root
rootPath=$(dirname $(dirname $(dirname $(dirname $(realpath $0)))))

# Path to config json file
jsonPath="${scriptDirPath}/optIn.config.json"

# This is to check the optIn.json file whether this dependency has already been added
isAdded=$(cat $jsonPath | jq ".eslint.added")

# To extract the downloaded file for its github URL
fileNameRegex="([^\/]+$)"

# GitHub urls to raw config file content
configAddresses=($(cat $jsonPath | jq -r ".eslint.configAddresses[]"))
numberOfConfigs=${#configAddresses[@]}

# Dependencies to install and their numbers
regularDeps=($(cat $jsonPath | jq -r ".eslint.regularDeps[]"))
regularDepsSize=${#regularDeps[@]}

devDeps=($(cat $jsonPath | jq -r ".eslint.devDeps[]"))
devDepSize=${#devDeps[@]}

# Script start
if [ "$isAdded" = false ]; then
  echo "Your eslint configurations have not been added to this project"
  exit
fi

# If my eslint config has already been fully installed
echo "Opting out. Removing your ESLint custom configurations..."

# Set "eslint" to false in optIn.json file
echo $(jq '.eslint.added = false' $jsonPath) >$jsonPath
echo "Uninstalling packages"

installationStatus="Uninstallation successful"

# Since it is the same command to remove regular and dev dependencies, merge them and remove them all
allDeps=("${devDeps[@]}" "${regularDeps[@]}")

if [ ${#allDeps[@]} -gt 0 ]; then
  echo "Removing eslint dependencies..."
  npm un ${allDeps[@]}
else
  installationStatus="No Packages to uninstall"
fi

echo "${installationStatus}. Remvoing your configs files.."

if [ $numberOfConfigs -gt 0 ]; then

  for address in ${configAddresses[@]}; do
    # Extract the filename from its url
    fileName=$(echo $address | grep -oE $fileNameRegex)
    rm "${rootPath}/${fileName}"
  done

  echo "Config files removed"
else
  echo "No custom config files were removed"
fi

echo "Opt out complete"
