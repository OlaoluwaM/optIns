# A collection of opt-in scripts

These scripts allow you to opt-in for certain tools/dependencies for your project

In order to use this tool you will need to install the following

+ jq: for working with json files in the command-line
+ curl: for making http requests from the command-line to download files

## Currently Supported Dependencies

+ ESLint
+ Tailwind Css
+ Jest

## How it works

Each script will ``npm install`` all the required packages for the specified tool. After, it will grab a config from my configs repo for that specified dependency and copy it to the root of the project directory

# Important

**Make sure to run this scripts in the root of your project directory**.
