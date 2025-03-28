#!/bin/bash

# Generic Functions
backupExistsCheck()
{
    local app_name="$1"
    local backup_file_name="$2"
    local backup_save_directory="$3"

    # Safeguarding
    if [ "$app_name" == "" ]; then
        isNotice "Empty app_name, something went wrong"
        exit
    fi

    # Check if the directory exists, create if it doesn't
    if [ ! -d "$backup_save_directory" ]; then
        result=$(sudo mkdir -p "$backup_save_directory")
        checkSuccess "Created backup directory."
    fi

    if [ -f "$backup_save_directory/$backup_file_name.zip" ]; then
        while true; do
            isQuestion "Backup file already exists for $app_name. Would you like to overwrite it? (y/n): "
            read -rp "" backupsinglefileexists
            if [[ -n "$backupsinglefileexists" ]]; then
                break
            fi
            isNotice "Please provide a valid input."
        done
    else
        isSuccessful "No backup files found to replace."
    fi

}
