#!/bin/bash

backupFindLatestFile()
{
    local app_name="$1"

    # Safeguarding
    if [ -z "$app_name" ]; then
        isNotice "Empty app_name, something went wrong"
        exit 1
    fi

    # Change to the backup save directory
    cd "$backup_save_directory" || { isNotice "Could not change directory to $backup_save_directory"; exit 1; }

    # Find the latest backup file inside the backup directory for the given app_name
    # We search for the file with the pattern "${backup_file_name}.zip"
    local latest_backup_file=$(sudo find . -maxdepth 1 -type f -name "${backup_file_name}.zip" | sort -r | head -n 1)

    # Check if a backup file was found
    if [ -z "$latest_backup_file" ]; then
        isNotice "No backup files found for $app_name on $backupDate."
    else
        backupTransferFile "$app_name" "$latest_backup_file"
    fi
}