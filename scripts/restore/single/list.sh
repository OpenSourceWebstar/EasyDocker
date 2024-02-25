#!/bin/bash

restoreSingleBackupList()
{
    local app_name="$1"
    local chosen_backup_file="$2"
    if [[ "$restoresingle" == [lL] ]]; then
        # Function to display a numbered list of app_names (zip files)
        select_app() {
            echo ""
            echo "##########################################"
            echo "###       Single App Restore List"
            echo "##########################################"
            echo ""
            app_list=()
            declare -A seen_apps
            local count=1

            for zip_file in "$backup_save_directory"/*.zip; do
                if [ -f "$zip_file" ]; then
                    # Extract the app_name from the filename using sed
                    local app_name=$(basename "$zip_file" | sed -E 's/.*-([^-]+)-backup-.*/\1/')
                    
                    # Check if the app_name is already in the associative array
                    if [ -z "${seen_apps[$app_name]}" ]; then
                        local app_list+=("$app_name")
                        seen_apps["$app_name"]=1  # Mark the app_name as seen
                        isOption "$count. $app_name"
                        ((count++))
                    fi
                fi
            done
        }

        # Function to display a numbered list of backup files for a selected app_name
        select_backup_file() {
            selected_app=$1
            echo ""
            echo "##########################################"
            echo "###  Available backups for $selected_app:"
            echo "##########################################"
            echo ""
            backup_list=()
            local count=1
            for zip_file in "$backup_save_directory"/*-$selected_app-backup-*; do
                if [ -f "$zip_file" ]; then
                    backup_list+=("$zip_file")
                    isOption "$count. $(basename "$zip_file")"
                    ((count++))
                fi
            done
        }

        # Main script starts here
        select_app

        # Read the user's choice number for app_name
        echo ""
        isQuestion "Select an application (number): "
        read -p "" chosen_app_number

        # Validate the user's choice number
        if [[ "$chosen_app_number" =~ ^[0-9]+$ ]]; then
            local selected_app_index=$((chosen_app_number - 1))

            if [ "$selected_app_index" -ge 0 ] && [ "$selected_app_index" -lt "${#app_list[@]}" ]; then
                local selected_app_name="${app_list[selected_app_index]}"
                select_backup_file "$selected_app_name"

                # Read the user's choice number for backup file
                echo ""
                isQuestion "Select a backup file (number): "
                read -p "" chosen_backup_number

                # Validate the user's choice number for backup file
                if [[ "$chosen_backup_number" =~ ^[0-9]+$ ]]; then
                    selected_backup_index=$((chosen_backup_number - 1))

                    if [ "$selected_backup_index" -ge 0 ] && [ "$selected_backup_index" -lt "${#backup_list[@]}" ]; then
                        chosen_backup_file=$(basename "${backup_list[selected_backup_index]}")
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
            else
                echo ""
                isNotice "Invalid application selection."
            fi
        else
            echo "" 
            isNotice "Invalid input for application selection."
        fi
    elif [[ "$restoresingle" == [rR] ]]; then
        restoreRemoteMenu single
    fi
}
