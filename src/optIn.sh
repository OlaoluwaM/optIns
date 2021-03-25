#!/usr/bin/env bash

# Rename $1 variable to make it more descriptive
tool=$1

# Path to this script
scriptDirPath=$(dirname $(realpath $0))

# Path to project root
rootPath=$(dirname $(dirname $(dirname $(realpath $0))))

# Path to config json file
jsonPath=$([[ -f "${rootPath}/optIn.config.json" ]] && echo "${rootPath}/optIn.config.json" || echo "${scriptDirPath}/optIn.config.json")

if [[ ! -f "$jsonPath" ]]; then
  echo "optIn.config.json file not found. Aborting..."
  exit
fi

# This is to check the optIn.json file whether this dependency has already been added
isAdded=$(cat $jsonPath | jq ".${tool}.added")

if [[ -z "$isAdded" ]]; then
  echo "Sorry, ${tool} is not configured in optIn.config.json file"
  exit
fi

# GitHub urls to raw config file content
configAddresses=($(cat $jsonPath | jq -r ".${tool}.configAddresses[]"))
numberOfConfigs=${#configAddresses[@]}

# Dependencies to install and their numbers
regularDeps=($(cat $jsonPath | jq -r ".${tool}.regularDeps[]"))
regularDepsSize=${#regularDeps[@]}

devDeps=($(cat $jsonPath | jq -r ".${tool}.devDeps[]"))
devDepSize=${#devDeps[@]}

# List of specified custom commands
customCommands=($(cat $jsonPath | jq -r ".${tool}.customCommands[]"))
customCommandsSize=${#customCommands[@]}

# Script start
if [ "$isAdded" = true ]; then
  echo "Your ${tool} custom configurations are already being used in this project"
  exit
fi

# If my tool configurations has not yet been added
echo "Your custom ${tool} configs have not been added. Opting in..."

# Set tool to true in optIn.json
echo $(jq ".${tool}.added = true" $jsonPath) >$jsonPath
installationStatus="Installation successful"

[ $regularDepsSize -eq 0 ] && [ $devDepSize -gt 0 ] && installationStatus="No Packages to install"

if [ $regularDepsSize -gt 0 ]; then
  echo "Installing specified regular dependencies for ${tool}"
  npm i ${regularDeps[@]}
fi

if [ $devDepSize -gt 0 ]; then
  echo "Installing specified dev dependencies for ${tool}"
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

# Here we will execute any custom commands
if [ $customCommandsSize -gt 0 ]; then

  for command in "${customCommands[*]}"; do
    eval "$command"
  done

fi

# Here we will execute any custom scripts defined in rootPath/optIn_custom_scripts/optIn
# Scripts can be shell or js scripts

customScriptsFolder="${rootPath}/optIn_custom_scripts/${tool}/optIn"

if [[ -d "$customScriptsFolder" ]]; then
  for script in $customScriptsFolder/*; do
    if [[ $script == *.js ]]; then
      $(which node) $script
    elif [[ $script == *.sh ]]; then
      source $script
    fi
  done
fi

echo "Opt in complete"
