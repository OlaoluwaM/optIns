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

# To extract the downloaded file for its github URL
fileNameRegex="([^\/]+$)"

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

# Custom files to remove
customFilesToRemove=($(cat $jsonPath | jq -r ".${tool}.otherFilesToRemove[]"))

# Script start
if [ "$isAdded" = false ]; then
  echo "Your ${tool} configurations have not been added to this project"
  exit
fi

# If my eslint config has already been fully installed
echo "Opting out. Removing your ${tool} custom configurations..."

# Set "eslint" to false in optIn.json file
echo $(jq ".${tool}.added = false" $jsonPath) >$jsonPath
echo "Uninstalling packages"

installationStatus="Uninstallation successful"

# Since it is the same command to remove regular and dev dependencies, merge them and remove them all
allDeps=("${devDeps[@]}" "${regularDeps[@]}")

if [ ${#allDeps[@]} -gt 0 ]; then
  echo "Removing ${tool} dependencies..."
  npm un ${allDeps[@]}
else
  installationStatus="No Packages to uninstall"
fi

echo "${installationStatus}. Remvoing your configs files.."

allFilesToRemove=("${configAddresses[@]}" "${customFilesToRemove[@]}")

if [ ${#allFilesToRemove[@]} -gt 0 ]; then

  for fileAddress in ${allFilesToRemove[@]}; do
    # Extract the filename from its url
    fileName=$(echo $fileAddress | grep -oE $fileNameRegex)
    rm "${rootPath}/${fileName}"
  done

  echo "Config files removed"
else
  echo "No custom config files were removed"
fi

# Here we will execute any custom commands
if [ $customCommandsSize -gt 0 ]; then

  for command in "${customCommands[*]}"; do
    eval "$command"
  done

fi

# Here we will execute any custom scripts defined in rootPath/optIn_custom_scripts/optOut
# Scripts can be shell or js scripts

customScriptsFolder="${rootPath}/optIn_custom_scripts/${tool}/optOut"

if [[ -d "$customScriptsFolder" ]]; then
  for script in $customScriptsFolder/*; do
    if [[ "$script" =~ ".js$" ]]; then
      $(which node) $script
    elif [[ "$script" =~ ".sh$" ]]; then
      source $script
    fi
  done
fi

echo "Opt out complete"
