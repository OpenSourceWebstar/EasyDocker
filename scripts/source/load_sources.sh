#!/bin/bash

# This is used for initial loading
# The starting point and is the only code that doesnt contain logic requirements

# Source "init.sh" and "variables.sh" if they exist, otherwise return an error
if [ -f "init.sh" ] && [ -f "variables.sh" ]; then
    source "init.sh"
    source "variables.sh"
else
    # Print an error message for any missing files
    [ ! -f "init.sh" ] && echo "Error: File 'init.sh' does not exist. Unable to source."
    [ ! -f "variables.sh" ] && echo "Error: File 'variables.sh' does not exist. Unable to source."
    echo "Files are missing, please run 'easydocker reset'"
    return 1
fi

# Source the remaining files if they all exist
if [ -f "${install_scripts_dir}source/loading/check_files.sh" ] && \
   [ -f "${install_scripts_dir}source/loading/initilize_files.sh" ] && \
   [ -f "${install_scripts_dir}source/loading/scan_files.sh" ]; then
    source "${install_scripts_dir}source/loading/check_files.sh"
    source "${install_scripts_dir}source/loading/initilize_files.sh"
    source "${install_scripts_dir}source/loading/scan_files.sh"
else
    # Print an error message for any missing files
    [ ! -f "${install_scripts_dir}source/loading/check_files.sh" ] && echo "Error: File '${install_scripts_dir}source/loading/check_files.sh' does not exist. Unable to source."
    [ ! -f "${install_scripts_dir}source/loading/initilize_files.sh" ] && echo "Error: File '${install_scripts_dir}source/loading/initilize_files.sh' does not exist. Unable to source."
    [ ! -f "${install_scripts_dir}source/loading/scan_files.sh" ] && echo "Error: File '${install_scripts_dir}source/loading/scan_files.sh' does not exist. Unable to source."
    echo "Files are missing, please run 'easydocker reset'"
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