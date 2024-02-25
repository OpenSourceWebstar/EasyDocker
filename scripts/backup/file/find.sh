#!/bin/bash

backupFindLatestFile()
{
    local app_name="$1"

    # Safeguarding
    if [ "$app_name" == "" ]; then
        isNotice "Empty app_name, something went wrong"
        exit
    fi

    if [ "$app_name" == "full" ]; then
        cd $backup_save_directory
        local latest_backup_file=$(sudo ls -t *"$backupDate.zip" | head -n 1)
        isNotice "Latest backup found file: $latest_backup_file"
        if [ -z "$latest_backup_file" ]; then
            isNotice "No backup files found for $app_name on $backupDate."
        else
            backupTransferFile $app_name $latest_backup_file;
        fi
    elif [ "$app_name" != "full" ]; then
        cd $backup_save_directory
        local latest_backup_file=$(sudo find . -maxdepth 1 -type f -regex ".*${app_name}.*${backupDate}\.zip" | sort -r | head -n 1)
        if [ -z "$latest_backup_file" ]; then
            isNotice "No backup files found for $app_name on $backupDate."
        else
            backupTransferFile $app_name $latest_backup_file;
        fi
    fi
}
