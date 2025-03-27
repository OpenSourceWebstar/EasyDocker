#!/bin/bash

# Main function for restoring a single backup
restoreBackupList() 
{
    # Interactive mode
    if [[ "$restoresingle" == [lL] ]]; then
        local app_list=()
        getAvailableLocalApps app_list

        local selected_app
        selectLocalApplication app_list selected_app || return

        local backup_list=()
        displayLocalBackups "$selected_app" backup_list

        local latest_backup_file
        latest_backup_file=$(getLatesLocaltBackupFile "$selected_app")

        if [[ -n "$latest_backup_file" ]]; then
            local use_latest
            read -p "Do you want to restore the latest backup? (y/n): " use_latest
            if [[ "$use_latest" =~ ^[yY]$ ]]; then
                restoreStart "$selected_app" "$latest_backup_file"
                return
            fi
        fi

        local selected_backup_file
        selectLocalBackupFile backup_list selected_backup_file || return

        echo "Selected backup file: $selected_backup_file"
        restoreStart "$selected_app" "$selected_backup_file"

    elif [[ "$restoresingle" == [rR] ]]; then
        restoreRemoteMenu single
    fi
}