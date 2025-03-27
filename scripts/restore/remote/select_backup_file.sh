#!/bin/bash

selectRemoteBackupFile() 
{
    selected_app=$1
    saved_selected_app=$selected_app
    echo ""
    echo "##########################################"
    echo "###    Available backups for $saved_selected_app:"
    echo "##########################################"
    echo ""

    backup_list=()
    local count=1

    # Use SSH to list remote backups for the selected app, sorted by modification date
    remote_backup_list=$(sshRemote "$remote_pass" "$remote_port" "${remote_user}@${remote_ip}" \
        "ls -t \"${remote_directory}/${restore_install_name}/$backup_type\"/*$saved_selected_app* 2>/dev/null")

    # Process the list of remote backup files
    while read -r zip_file; do
        backup_list+=("$zip_file")
        isOption "$count. $(basename "$zip_file")"
        ((count++))
    done <<< "$remote_backup_list"

    # Check if any backups exist
    if [[ ${#backup_list[@]} -eq 0 ]]; then
        isNotice "No backups found for $saved_selected_app."
        return
    fi

    # Add an option to auto-select the latest backup
    isOption "0. Auto-select the latest backup"
    isOption "b. Go back"

    while true; do
        echo ""
        isQuestion "Select a backup file (number), '0' for the latest backup, or 'b' to go back: "
        read -rp "" chosen_backup_option

        if [[ "$chosen_backup_option" == "b" ]]; then
            selectRemoteApp  # Go back to the application selection
            return
        elif [[ "$chosen_backup_option" == "0" ]]; then
            # Automatically pick the latest backup file
            latest_backup_file=$(basename "${backup_list[0]}")
            echo ""
            isNotice "Automatically selected latest backup: $latest_backup_file"
            restoreStart "$saved_selected_app" "$latest_backup_file" "${remote_directory}/${restore_install_name}/$backup_type"
            return
        elif [[ "$chosen_backup_option" =~ ^[0-9]+$ ]]; then
            selected_backup_index=$((chosen_backup_option - 1))

            if [ "$selected_backup_index" -ge 0 ] && [ "$selected_backup_index" -lt "${#backup_list[@]}" ]; then
                chosen_backup_file=$(basename "${backup_list[selected_backup_index]}")
                echo ""
                isNotice "You selected: $chosen_backup_file"
                restoreStart "$saved_selected_app" "$chosen_backup_file" "${remote_directory}/${restore_install_name}/$backup_type"
                return
            else
                echo ""
                isNotice "Invalid backup file selection."
            fi
        else
            echo ""
            isNotice "Invalid input. Please select a valid option, '0' for the latest backup, or 'b' to go back."
        fi
    done
}
