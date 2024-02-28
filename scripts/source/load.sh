#!/bin/bash

# This is used for initial loading
# The starting point and is the only code that doesnt contain logic requirements

# Source files if they exist, otherwise return an error
if [ -f "init.sh" ] && \
   [ -f "variables.sh" ] && \
   [ -f "${install_scripts_dir}source/loading/check.sh" ] && \
   [ -f "${install_scripts_dir}source/loading/initilize.sh" ] && \
   [ -f "${install_scripts_dir}source/loading/scan.sh" ]; then
    source "init.sh"
    source "variables.sh"
    source "${install_scripts_dir}source/loading/check.sh"
    source "${install_scripts_dir}source/loading/initilize.sh"
    source "${install_scripts_dir}source/loading/scan.sh"
else
    # Print an error message for any missing files
    [ ! -f "init.sh" ] && echo "Error: File 'init.sh' does not exist. Unable to source."
    [ ! -f "variables.sh" ] && echo "Error: File 'variables.sh' does not exist. Unable to source."
    [ ! -f "${install_scripts_dir}source/loading/check.sh" ] && echo "Error: File '${install_scripts_dir}source/loading/check.sh' does not exist. Unable to source."
    [ ! -f "${install_scripts_dir}source/loading/initilize.sh" ] && echo "Error: File '${install_scripts_dir}source/loading/initilize.sh' does not exist. Unable to source."
    [ ! -f "${install_scripts_dir}source/loading/scan.sh" ] && echo "Error: File '${install_scripts_dir}source/loading/scan.sh' does not exist. Unable to source."
    return 1
fi

# For starting the script
if [[ $init_run_flag == "true" ]]; then
    # For loading EasyDocker
    sourceCheckFiles "run";
elif [[ $init_run_flag == "false" ]]; then
    # For using the CLI
    sourceCheckFiles "cli";
fi