# A collection of optIn scripts

These scripts allow you to optIn for certain tools/dependencies for your project

In order to use this tool you will need to install the following

+ jq: for working with json files in the command-line
+ curl: for making http requests from the command-line to download files

## Currently Supported Dependencies

+ ESLint
+ Tailwind CSS
+ Tailwind CSS with CRA

## How it works

+ Each script will ``npm install`` all the required packages for the specified tool.
+ After, it will grab a config from my configs repo for that specified dependency and copy it to the root of the project directory
+ Then it will perform any custom commands afterwards
+ Additionally, if the dependency is already installed in the project running the script will remove it
+ You can have your own custom ``optIn.config.json`` file at the root directory of your project for the scripts to use in both opt-in and opt-out. Check out the example ``optIn.config.json`` file in the src for how to structure your own

+ You can add custom commands for the scripts to run at the end for each dependency/tool in the ``optIn.config.json`` file
