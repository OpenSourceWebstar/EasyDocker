#!/bin/bash

sourceInitilize()
{
    local flag="$1"

    # We will only show the header for the full app
    if [[ $flag == "run" ]]; then
        echo ""
        echo "####################################################"
        echo "###       Loading EasyDocker Startup Files       ###"
        echo "####################################################"
        echo ""
        echo "${YELLOW}NOTICE:${NC} If you are experiencing loading issues..."
        echo "${YELLOW}NOTICE:${NC} Please run the following : 'easydocker reset'"
        echo ""
    fi

    # Loading the full file list
    local file_list_directory="files"
    # Check if the directory exists
    if [ -d "$file_list_directory" ]; then
        # Loop through each file in the directory
        for file in "$file_list_directory"/*; do
            # Check if the file is readable and is not a directory
            if [ -f "$file" ] && [ -r "$file" ]; then
                # Source the file
                source "$file"
            fi
        done
    else
        echo "Directory $directory does not exist. Unable to start!"
        return
    fi

    # For loading files needed for the full app or CLI
    if [[ $flag == "run" ]]; then
        files_to_source=("${files_easydocker_app[@]}")
    elif [[ $flag == "cli" ]]; then
        files_to_source=("${files_easydocker_cli[@]}")
    fi

    # Checking for missing files
    for file_to_source in "${files_to_source[@]}"; do
        if [ ! -f "$file_to_source" ]; then
            echo "NOTICE: Missing file: $file_to_source"
        else
            source "$file_to_source"
            #echo "Sourced file: $file_to_source"
        fi
    done

    # Loading of all files
    sourceScanFiles "easydocker_configs";
    sourceScanFiles "app_configs";
    sourceScanFiles "containers";
}
