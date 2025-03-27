#!/bin/bash

# Function to restore the latest backup for a given app
restoreLatestLocalBackup()
{
    local app_name="$1"
    local latest_backup_file
    
    latest_backup_file=$(getLatesLocaltBackupFile "$app_name")

    if [[ -z "$latest_backup_file" ]]; then
        echo "No backups found for $app_name."
        return 1
    fi

    echo "Automatically restoring latest backup for $app_name: $latest_backup_file"
    restoreStart "$app_name" "$latest_backup_file"
}
