#!/usr/bin/env bash

# Script to remove my eslint configurations from my project

# Path to this script
scriptPath=$(dirname $(realpath $0))

# Path to project root
rootPath=$(dirname $(dirname $(dirname $(realpath $0))))

# Path to config json file
jsonPath="${scriptPath}/optIn.config.json"

# This is to check the opt-in.json file whether this dependency has already been added
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
  echo "Your eslint config has not been added to this project"
  exit
fi

# If my eslint config has already been fully installed
echo "Opting out. Removing your ESLint custom configurations..."

# Set "eslint" to false in opt-in.json file
echo $(jq '.eslint.added = false' $jsonPath) >$jsonPath
echo "Uninstalling packages"

installationStatus="Uninstallation successful"

# Since it is the same command to remove regular and dev dependencies, merge them and remove them all
allDeps=("${devDeps[@]}" "${regularDeps[@]}")

if [ ${#allDeps[@]} -gt 0 ]; then
  echo "Removing your specified dependencies..."
  npm un ${allDeps[@]}
else
  installationStatus="No Packages to uninstall"
fi

if [ $numberOfConfigs -gt 0 ]; then
  echo "${installationStatus}. Remvoing your configs files.."

  for address in ${configAddresses[@]}; do
    # Extract the filename from its url
    fileName=$(echo $address | grep -oE $fileNameRegex)
    rm "${rootPath}/${fileName}"
  done

  echo "Configs removed"
else
  echo "No custom configs to remove"
fi

echo "Opt out complete"
