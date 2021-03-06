#!/usr/bin/env bash

# Path to this script
scriptDirPath=$(dirname $(dirname $(realpath $0)))

# Path to project root
rootPath=$(dirname $(dirname $(dirname $(dirname $(realpath $0)))))

# Path to config json file
jsonPath="${scriptDirPath}/optIn.config.json"

# This is to check the optIn.json file whether this dependency has already been added
isAdded=$(cat $jsonPath | jq ".tailwindCSS.added")

# To extract the downloaded file for its github URL
fileNameRegex="([^\/]+$)"

# GitHub urls to raw config file content
configAddresses=($(cat $jsonPath | jq -r ".tailwindCSS.configAddresses[]"))
numberOfConfigs=${#configAddresses[@]}

# Dependencies to install and their numbers
regularDeps=($(cat $jsonPath | jq -r ".tailwindCSS.regularDeps[]"))
regularDepsSize=${#regularDeps[@]}

devDeps=($(cat $jsonPath | jq -r ".tailwindCSS.devDeps[]"))
devDepSize=${#devDeps[@]}

# Whether or not the default TailwindCSS config file should be generated
useDefaultConfigFile=$(jq ".tailwindCSS.customProperties.useDefaultConfigFile" $jsonPath)

# Script start
if [ "$isAdded" = true ]; then
  echo "Your TailwindCSS custom configurations are already being used in this project"
  exit
fi

echo "TailwindCSS not added. Opting in..."

# Set "tailwindCSS" to true in optIn.json
echo $(jq '.tailwindCSS.added = true' $jsonPath) >$jsonPath
installationStatus="Installation successful"

[ $regularDepsSize -eq 0 ] && [ $devDepSize -gt 0 ] && installationStatus="No Packages to install"

if [ $regularDepsSize -gt 0 ]; then
  echo "Installing specified regular dependencies for TailwindCSS"
  npm i ${regularDeps[@]}
fi

if [ $devDepSize -gt 0 ]; then
  echo "Installing specified dev dependencies for TailwindCSS"
  npm i -D ${devDeps[@]}
fi

if [ $numberOfConfigs -gt 0 ]; then
  echo "${installationStatus}. Fetching your configs from GitHub.."

  for address in ${configAddresses[@]}; do
    # Do not download custom TailwindCSS config if we want to use the default generated one
    [ "$useDefaultConfigFile" = true ] && [[ "$address" = *tailwind* ]] && continue

    # Download file from url to root directory
    curl -LJO $address $rootPath
  done
  echo "Configs downloaded"
else
  echo "No configs were available for download, or you are yet to specify any"
fi

if [ "$useDefaultConfigFile" = true ]; then
  echo "Installing default TailwindCSS config..."
  npx tailwind init tailwind.js --full
  echo "Installation complete"
fi

echo "Adding Tailwind import statement to index.js..."
sed -i "1s/^/import 'tailwindcss\/tailwind.css'\n/" "${rootPath}/src/index.js"

echo "Opt in complete"
