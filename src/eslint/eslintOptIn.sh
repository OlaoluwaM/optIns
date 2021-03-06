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
if [ "$isAdded" = true ]; then
  echo "Your eslint custom configurations are already being used in this project"
  exit
fi

# If my eslint configurations has not yet been added
echo "Your custom eslint configs have not been added. Opting in..."

# Set "eslint" to true in optIn.json
echo $(jq '.eslint.added = true' $jsonPath) >$jsonPath
installationStatus="Installation successful"

[ $regularDepsSize -eq 0 ] && [ $devDepSize -gt 0 ] && installationStatus="No Packages to install"

if [ $regularDepsSize -gt 0 ]; then
  echo "Installing specified regular dependencies for eslint"
  npm i ${regularDeps[@]}
fi

if [ $devDepSize -gt 0 ]; then
  echo "Installing specified dev dependencies for eslint"
  npm i -D ${devDeps[@]}
fi

if [ $numberOfConfigs -gt 0 ]; then
  echo "${installationStatus}. Fetching your configs from GitHub.."

  for address in ${configAddresses[@]}; do
    # Download file from url to root directory
    curl -LJO $address $rootPath
  done

  echo "Configs downloaded"
else
  echo "No configs were available for download, or you are yet to specify any"
fi

echo "Opt in complete"
