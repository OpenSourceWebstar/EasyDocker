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

    if [ -f "$backup_save_directory/$backup_file_name.zip" ]; then
        while true; do
            isQuestion "Backup file already exists for $app_name. Would you like to overwrite it? (y/n): "
            read -rp "" backupfileexists
            if [[ -n "$backupfileexists" ]]; then
                break
            fi
            isNotice "Please provide a valid input."
        done
    else
        isSuccessful "No backup files found to replace."
    fi

}
