#!/bin/bash

zipFile() 
{
    local passphrase="$1"
    local zip_file="$2"
    local zip_directory="$3"

    # Calculate the total size of the directory to zip
    local total_size=$(du -sb "$zip_directory" | awk '{print $1}')

    # Run the SSH command using the existing SSH variables with progress
    local result=$(tar -cf - "$zip_directory" | pv -s "$total_size" | zip -r -MM -e -P "$passphrase" "$zip_file" -)
    checkSuccess "Zipped up $(basename "$zip_file")"

    local result=$(sudo chown $sudo_user_name:$sudo_user_name "$zip_file")
    checkSuccess "Updating $(basename "$zip_file") with $sudo_user_name ownership"
}
