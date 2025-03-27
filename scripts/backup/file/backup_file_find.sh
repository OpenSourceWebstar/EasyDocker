#!/bin/bash

backupFindLatestFile()
{
    local app_name="$1"

    # Safeguarding
    if [ "$app_name" == "" ]; then
        isNotice "Empty app_name, something went wrong"
        exit
    fi

    cd $backup_save_directory
    local latest_backup_file=$(sudo find . -maxdepth 1 -type f -regex ".*${app_name}.*${backupDate}\.zip" | sort -r | head -n 1)
    if [ -z "$latest_backup_file" ]; then
        isNotice "No backup files found for $app_name on $backupDate."
    else
        backupTransferFile $app_name $latest_backup_file;
    fi
}
