#!/usr/bin/env bash

# Path to this script
# Path to this script
scriptPath=$(dirname $(realpath $0))

# Path to project root
rootPath=$(dirname $(dirname $(dirname $(realpath $0))))

jsonPath="${scriptPath}/opt-in.config.json"
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
  # If ESLint is not yet installed
  echo "ESLint not added. Opting in..."

  # Set it "eslint" to true in opt-in.json
  echo $(jq '.eslint.added = true' $jsonPath) >$jsonPath
  echo "Installing necessary packages"

  installationStatus="Installation successful"

  if [ $devDepSize -gt 0 ]; then
    npm i -D ${devDeps[@]}

  elif [ $regularDepsSize -gt 0 ]; then
    npm i ${regularDeps[@]}
  else
    installationStatus="No Packages to install"
  fi

  echo "${installationStatus}. Fetching configs.."

  if [ $numberOfConfigs -gt 0 ]; then

    for address in ${configAddresses[@]}; do
      # Download file from url to root directory
      curl -LJO $address $rootPath
    done

    echo "Configs downloaded"
  else
    echo "No configs for this dependency"
  fi

  echo "Opt in complete"
else
  # If eslint is already fully installed
  echo "Opting out. Removing ESLint..."

  # Set "eslint" to false in opt-in.json file
  echo $(jq '.eslint.added = false' $jsonPath) >$jsonPath
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
      # Extract the filename from its url
      fileName=$(echo $address | grep -oE $fileNameRegex)
      rm "${rootPath}/${fileName}"
    done

    echo "Configs removed"
  else
    echo "No configs to remove"
  fi

  echo "Opt out complete"
fi
