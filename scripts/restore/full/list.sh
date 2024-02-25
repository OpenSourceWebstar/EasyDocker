#!/bin/bash

restoreFullBackupList() 
{
    if [[ "$restorefull" == [lL] ]]; then
        # Function to display a numbered list of backup files in the single folder
        select_backup_file() {
            echo ""
            echo "##########################################"
            echo "###     Available Full Backup Files"
            echo "##########################################"
            echo ""
            backup_list=()
            local count=1
            for zip_file in "$backup_save_directory"/*.zip; do
                if [ -f "$zip_file" ]; then
                    backup_list+=("$zip_file")
                    isOption "$count. $(basename "$zip_file")"
                    ((count++))
                fi
            done
            if [ "${#backup_list[@]}" -eq 0 ]; then
                echo ""
                isNotice "No backup files found in $backup_save_directory."
                return 1
            fi
        }

        # Main script starts here
        select_backup_file || return 1

        # Read the user's choice number for backup file
        echo ""
        isQuestion "Select a backup file (number): "
        read -p "" chosen_backup_number

        # Validate the user's choice number for backup file
        if [[ "$chosen_backup_number" =~ ^[0-9]+$ ]]; then
            selected_backup_index=$((chosen_backup_number - 1))

            if [ "$selected_backup_index" -ge 0 ] && [ "$selected_backup_index" -lt "${#backup_list[@]}" ]; then
                chosen_backup_file=$(basename "${backup_list[selected_backup_index]}")
                local selected_app_name=full
                echo ""
                isNotice "You selected: $chosen_backup_file"
                restoreStart $selected_app_name $chosen_backup_file
            else
                echo ""
                isNotice "Invalid backup file selection."
            fi
        else
            echo ""
            isNotice "Invalid input for backup file selection."
        fi
    elif [[ "$restorefull" == [rR] ]]; then
        restoreRemoteMenu full
    fi
}        
