#!/usr/bin/env bash

# Script to add my eslint configuration to my project

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
if [ "$isAdded" = true ]; then
  echo "Eslint already being used in project"
  exit
fi

# If my eslint config has not yet been added
echo "Your custom eslint configs have not been added. Opting in..."

# Set it "eslint" to true in opt-in.json
echo $(jq '.eslint.added = true' $jsonPath) >$jsonPath
installationStatus="Installation successful"

[ $regularDepsSize -eq 0 ] && [ $devDepSize -gt 0 ] && installationStatus="No Packages to install"

if [ $regularDepsSize -gt 0 ]; then
  echo "Installing your specified regular dependencies"
  npm i ${regularDeps[@]}
fi

if [ $devDepSize -gt 0 ]; then
  echo "Installing specified dev dependencies"
  npm i -D ${devDeps[@]}
fi

if [ $numberOfConfigs -gt 0 ]; then
  echo "${installationStatus}. Fetching yout configs from GitHub.."

  for address in ${configAddresses[@]}; do
    # Download file from url to root directory
    curl -LJO $address $rootPath
  done

  echo "Configs downloaded"
else
  echo "No configs were available for download, or you are yet to specify any"
fi

echo "Opt in complete"
