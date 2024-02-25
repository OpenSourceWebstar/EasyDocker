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

    if [ "$app_name" == "full" ]; then
        if [ -f "$backup_save_directory/$backup_file_name.zip" ]; then
            while true; do
                isQuestion "Full Backup file already exists. Would you like to overwrite it? (y/n): "
                read -rp "" backupfullfileexists
                if [[ -n "$backupfullfileexists" ]]; then
                    break
                fi
                isNotice "Please provide a valid input."
            done
        else
            isSuccessful "No backup files found to replace."
        fi
    elif [ "$app_name" != "full" ]; then
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
    fi
}
