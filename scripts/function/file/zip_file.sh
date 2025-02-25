#!/bin/bash

zipFile() 
{
    local passphrase="$1"
    local zip_file="$2"
    local zip_directory="$3"

    # Calculate the total size of the directory to zip (with sudo to avoid permission issues)
    local total_size=$(sudo du -sb "$zip_directory" 2>/dev/null | awk '{print $1}')

    # Check if the size calculation succeeded
    if [[ -z "$total_size" ]]; then
        echo "Error: Could not determine directory size. Check permissions."
        return 1
    fi

    # Run the zip command with progress
    local result=$(sudo tar -cf - "$zip_directory" 2>/dev/null | pv -s "$total_size" | sudo zip -r -MM -e -P "$passphrase" "$zip_file" -)
    checkSuccess "Zipped up $(basename "$zip_file")"

    local result=$(sudo chown $sudo_user_name:$sudo_user_name "$zip_file")
    checkSuccess "Updating $(basename "$zip_file") with $sudo_user_name ownership"
}
