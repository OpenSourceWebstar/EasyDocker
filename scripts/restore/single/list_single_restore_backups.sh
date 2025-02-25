#!/bin/bash

restoreSingleBackupList() 
{
    if [[ "$restorefull" == [lL] ]]; then
        local app_list=()
        local backup_list=()
        
        # Function to display a numbered list of applications
        displayApps() 
        {
            echo ""
            echo "##########################################"
            echo "###       Single App Restore List"
            echo "##########################################"
            echo ""
            echo "Available applications:"
            for ((i = 0; i < ${#app_list[@]}; i++)); do
                echo "$((i + 1)). ${app_list[$i]}"
            done
            echo ""
        }

        # Function to display a numbered list of backup files for a selected application
        displayBackups() 
        {
            local selected_app_name="$1"
            echo "##########################################"
            echo "###  Available backups for $selected_app_name:"
            echo "##########################################"
            echo ""
            count=1
            for backup_file in "$backup_save_directory"/*-"$selected_app_name"-backup-*; do
                echo "$count. $(basename "$backup_file")"
                ((count++))
            done
            echo ""
        }

        # Collect available backups
        for zip_file in "$backup_save_directory"/*.zip; do
            if [ -f "$zip_file" ]; then
                local app_name=$(basename "$zip_file" | sed -E 's/.*-([^-]+)-backup-.*/\1/')
                app_list+=("$app_name")
                backup_list["$app_name"]="$zip_file"
            fi
        done

        displayApps

        # Select an application
        local chosen_app_index
        read -p "Select an application (number): " chosen_app_index
        if [[ ! "$chosen_app_index" =~ ^[0-9]+$ || "$chosen_app_index" -lt 1 || "$chosen_app_index" -gt ${#app_list[@]} ]]; then
            echo "Invalid application selection."
            return
        fi

        local selected_app_name="${app_list[chosen_app_index - 1]}"
        local selected_backup_file="${backup_list[$selected_app_name]}"

        displayBackups "$selected_app_name"

        # Select a backup
        local chosen_backup_index
        read -p "Select a backup file (number): " chosen_backup_index
        if [[ ! "$chosen_backup_index" =~ ^[0-9]+$ || "$chosen_backup_index" -lt 1 || "$chosen_backup_index" -gt $count ]]; then
            echo "Invalid backup selection."
            return
        fi

        local selected_backup_file="${backup_list[$chosen_backup_index - 1]}"
        echo "Selected backup file: $selected_backup_file"
        restoreStart "$selected_app_name" "$selected_backup_file"

    elif [[ "$restoresingle" == [rR] ]]; then
        restoreRemoteMenu single
    fi
}
