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

# Whether or not the default TailwindCSS should be generated
useDefaultConfigFile=$(jq ".tailwindCSS.customProperties.useDefaultConfigFile" $jsonPath)

# Script start
if [ "$isAdded" = false ]; then
  echo "Your TailwindCSS configurations have not been added to this project"
  exit
fi

echo "Opting out. Removing TailwindCSS configurations..."

# Set "tailwindCSS" to false in optIn.json file
echo $(jq '.tailwindCSS.added = false' $jsonPath) >$jsonPath
echo "Uninstalling packages"
installationStatus="Uninstallation successful"

# Since it is the same command to remove regular and dev dependencies, merge them and remove them all
allDeps=("${devDeps[@]}" "${regularDeps[@]}")

if [ ${#allDeps[@]} -gt 0 ]; then
  echo "Removing dependencies for TailwindCSS..."
  npm un ${allDeps[@]}
else
  installationStatus="No Packages to uninstall"
fi

echo "${installationStatus}. Remvoing your configs files.."

if [ $numberOfConfigs -gt 0 ]; then

  for address in ${configAddresses[@]}; do
    [ "$useDefaultConfigFile" = true ] && [[ "$address" = *tailwind* ]] && continue

    # Extract the filename from its url
    fileName=$(echo $address | grep -oE $fileNameRegex)
    rm "${rootPath}/${fileName}"
  done
  echo "Configs files removed"
else
  echo "No custom configs to remove"
fi

if [ "$useDefaultConfigFile" = true ]; then
  echo "Removing default tailwind.js config file"
  rm "${rootPath}/tailwind.js"
fi

echo "Removing TailwindCSS import statement from index.js"
tailwindImportLineNumber=$(grep -Rn "import 'tailwindcss/tailwind.css'" "${rootPath}/src/index.js" | grep -oE '[0-9]+')
sed -i "${tailwindImportLineNumber}d" "${rootPath}/src/index.js"

echo "Opt out complete"
