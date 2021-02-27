#!/usr/bin/env bash

# This is to check the opt-in.json file whether this dependency has already been added
isAdded=$(cat opt-in.json | jq ".eslint")

# To extract the downloaded file for its github URL
fileNameRegex="([^\/]+$)"

# GitHub urls to raw config file content
configAddresses=("https://raw.githubusercontent.com/OlaoluwaM/thefellowshipoftheconfigs/main/.eslintrc.js" "https://raw.githubusercontent.com/OlaoluwaM/thefellowshipoftheconfigs/main/.eslintignore" "https://raw.githubusercontent.com/OlaoluwaM/thefellowshipoftheconfigs/main/.prettierrc" "https://raw.githubusercontent.com/OlaoluwaM/thefellowshipoftheconfigs/main/.prettierignore" "prettier")
numberOfConfigs=${#configAddresses[@]}

# Dependencies to install and their numbers
regularDeps=()
regularDepsSize=${#regularDeps[@]}

devDeps=(eslint eslint-config-prettier eslint-plugin-better-styled-components eslint-plugin-filenames eslint-plugin-jsx-a11y eslint-plugin-prettier eslint-plugin-react eslint-plugin-react-hooks prettier)
devDepSize=${#devDeps[@]}

# Script start
if [ "$isAdded" = "false" ]; then
  # If ESLint is not yet installed
  echo "ESLint not added. Opting in..."

  # Set it "eslint" to true in opt-in.json
  echo $(jq '.eslint = true' opt-in.json) >opt-in.json
  echo "Installing necessary packages"

  installationStatus="Installation successful"

  if [ $devDepSize -gt 0]; then
    for package in "${devDeps[@]}"; do
      npm i -D $package
    done

  elif [ $regularDepsSize -gt 0 ]; then
    for package in "${regularDeps[@]}"; do
      npm i $package
    done

  else
    installationStatus="No Packages to install"
  fi

  echo "${installationStatus}. Fetching configs.."

  if [ $numberOfConfigs -gt 0 ]; then
    for address in "${configAddresses[@]}"; do
      # Download file from url to root directory
      curl -LJO $address $PWD
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
  echo $(jq '.eslint = false' opt-in.json) >opt-in.json
  echo "Uninstalling packages"

  installationStatus="Uninstallation successful"

  # Since it is the same command to remove regular and dev dependencies, merge them and remove them all
  allDeps=("${devDeps[@]}" "${regularDeps[@]}")

  if [ ${#allDeps[@]} -gt 0 ]; then
    for package in "${allDeps[@]}"; do
      npm un $package
    done

  else
    installationStatus="No Packages to uninstall"
  fi

  echo "${installationStatus}. Remvoing configs.."

  if [ $numberOfConfigs -gt 0 ]; then
    for address in "${configAddresses[@]}"; do
      # Extract the filename from its url
      fileName=$(echo $address | grep -oE $fileNameRegex)

      rm "${PWD}/${fileName}"
    done

    echo "Configs removed"
  else
    echo "No configs to remove"
  fi

  echo "Opt out complete"
fi
