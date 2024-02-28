#!/bin/bash

# This is used for initial loading
# The starting point and is the only code that doesnt contain logic requirements
source "init.sh"
source "variables.sh"
source "${install_scripts_dir}source/loading/check.sh"
source "${install_scripts_dir}source/loading/initilize.sh"
source "${install_scripts_dir}source/loading/scan.sh"

# For starting the script
if [[ $init_run_flag == "true" ]]; then
    # For loading EasyDocker
    sourceCheckFiles "run";
elif [[ $init_run_flag == "false" ]]; then
    # For using the CLI
    sourceCheckFiles "cli";
fi