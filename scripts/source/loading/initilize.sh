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
        echo -e "${YELLOW}NOTICE:${NC} If you are experiencing loading issues..."
        echo -e "${YELLOW}NOTICE:${NC} Please run the following : 'easydocker reset'"
        echo ""
    fi

    # Directory containing the files to source recursively
    local file_list_directory="${install_scripts_dir}source/files"

    # Check if the directory exists
    if [ -d "$file_list_directory" ]; then
        # Use find to get a list of all files (excluding directories) in the directory and its subdirectories
        local file_list=$(find "$file_list_directory" -type f -name "*.sh")

        # Loop through each file in the file list
        while IFS= read -r file; do
            # Source the file
            source "$file"
        done <<< "$file_list"
    else
        echo "Directory $file_list_directory does not exist. Unable to start!"
        return 1
    fi

    # For loading files needed for the full app or CLI
    if [[ $flag == "run" ]]; then
        files_to_source=("${files_easydocker_app[@]}")
    elif [[ $flag == "cli" ]]; then
        files_to_source=("${files_easydocker_cli[@]}")
    fi

    # Checking for missing files
    for file_to_source in "${files_to_source[@]}"; do
        if [ ! -f "${install_scripts_dir}${file_to_source}" ]; then
            echo "NOTICE: Missing file: ${install_scripts_dir}${file_to_source}"
        else
            source "${install_scripts_dir}${file_to_source}"
            #echo "Sourced file: ${install_scripts_dir}${file_to_source}"
        fi
    done

    # Loading of all files
    sourceScanFiles "easydocker_configs";
    sourceScanFiles "app_configs";
    sourceScanFiles "containers";
}
