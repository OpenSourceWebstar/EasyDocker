#!/bin/bash

zipFile() 
{
    local passphrase="$1"
    local zip_file="$2"
    local zip_directory="$3"

    # Run the SSH command using the existing SSH variables
    local result=$(sudo zip -r -MM -e -P $passphrase $zip_file $zip_directory)
    checkSuccess "Zipped up $(basename "$zip_file")"

    local result=$(sudo chown $sudo_user_name:$sudo_user_name "$zip_file")
    checkSuccess "Updating $(basename "$zip_file") with $sudo_user_name ownership"
}
