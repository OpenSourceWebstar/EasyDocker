#!/bin/bash

# Function to allow the user to manually select a backup
selectLocalBackupFile() 
{
    local -n backup_list_ref=$1
    local -n selected_backup_ref=$2

    local chosen_index
    read -p "Select a backup file (number): " chosen_index
    if [[ ! "$chosen_index" =~ ^[0-9]+$ || -z "${backup_list_ref[$chosen_index]}" ]]; then
        echo "Invalid backup selection."
        return 1
    fi

    selected_backup_ref="${backup_list_ref[$chosen_index]}"
}
