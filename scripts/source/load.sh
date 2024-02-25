#!/bin/bash

# This is used for initial loading
# The starting point and is the only code that doesnt contain logic requirements
source "scripts/source/loading/check.sh"
source "scripts/source/loading/initilize.sh"
source "scripts/source/loading/scan.sh"

# For starting the script
if [[ $init_run_flag == "true" ]]; then
    # For loading EasyDocker
    sourceCheckFiles "run";
elif [[ $init_run_flag == "false" ]]; then
    # For using the CLI
    sourceCheckFiles "cli";
fi