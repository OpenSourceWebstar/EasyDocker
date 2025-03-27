#!/bin/bash

# Function to display available backups for a selected app
displayLocalBackups() 
{
    local app_name="$1"
    local -n backup_list_ref=$2

    echo ""
    echo "##########################################"
    echo "###  Available backups for $selected_app:"
    echo "##########################################"
    echo ""

    local index=1
    for backup_file in "$backup_save_directory"/*-"$app_name"-backup-*; do
        if [[ -f "$backup_file" ]]; then
            backup_list_ref["$index"]="$backup_file"
            echo "$index) $backup_file"
            ((index++))
        fi
    done
    
    echo ""
}
