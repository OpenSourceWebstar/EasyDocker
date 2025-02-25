#!/bin/bash

restoreCopyFile() 
{
    local remote_path="$1"
    local remote_path_save=$remote_path

    # Extract the date from the filename
    RestoreBackupDate=$(echo "$chosen_backup_file" | cut -d'-' -f1-3)
    isNotice "The Backup file is $chosen_backup_file, using this for restore."

    local destination_path="$RESTORE_SAVE_DIRECTORY/$chosen_backup_file"

    # Check if the backup file already exists
    if [ -f "$destination_path" ]; then
        isNotice "Backup file $chosen_backup_file already exists in the restore directory. Skipping download."
        echo ""
        while true; do
            isQuestion "Would you like to Redownload $chosen_backup_file? (y/n): "
            read -p "" redownload_backup_file
            if [[ -n "$redownload_backup_file" ]]; then
                break
            fi
            isNotice "Please provide a valid input."
        done
        if [[ "$redownload_backup_file" == [yY] ]]; then
            # Perform the copy or download
            if [[ "$restorefull" == [lL] ]] || [[ "$restoresingle" == [lL] ]] || [[ "$restorefull" == [mM] ]] || [[ "$restoresingle" == [mM] ]]; then
                local result=$(copyFile "loud" "$backup_save_directory/$chosen_backup_file" "$RESTORE_SAVE_DIRECTORY" "$docker_install_user" | pv -p -e -r > /dev/null)
                checkSuccess "Copying over $chosen_backup_file to the local Restore Directory"
            elif [[ "$restorefull" == [rR] ]] || [[ "$restoresingle" == [rR] ]]; then
                if [[ "$remote_server" == "1" ]]; then
                    local result=$(sudo sshpass -p "$CFG_BACKUP_REMOTE_1_PASS" scp -o StrictHostKeyChecking=no "$CFG_BACKUP_REMOTE_1_USER"@"$CFG_BACKUP_REMOTE_1_IP":"$remote_path_save/$chosen_backup_file" "$destination_path" | pv -p -e -r > /dev/null)
                    checkSuccess "Copy $chosen_backup_file from $CFG_BACKUP_REMOTE_1_IP to $RESTORE_SAVE_DIRECTORY"
                elif [[ "$remote_server" == "2" ]]; then
                    local result=$(sudo sshpass -p "$CFG_BACKUP_REMOTE_2_PASS" scp -o StrictHostKeyChecking=no "$CFG_BACKUP_REMOTE_2_USER"@"$CFG_BACKUP_REMOTE_2_IP":"$remote_path_save/$chosen_backup_file" "$destination_path" | pv -p -e -r > /dev/null)
                    checkSuccess "Copy $chosen_backup_file from $CFG_BACKUP_REMOTE_2_IP to $RESTORE_SAVE_DIRECTORY"
                fi
            fi
        fi
    else
        # Perform the copy or download
        if [[ "$restorefull" == [lL] ]] || [[ "$restoresingle" == [lL] ]] || [[ "$restorefull" == [mM] ]] || [[ "$restoresingle" == [mM] ]]; then
            local result=$(copyFile "loud" "$backup_save_directory/$chosen_backup_file" "$RESTORE_SAVE_DIRECTORY" "$docker_install_user" | pv -p -e -r > /dev/null)
            checkSuccess "Copying over $chosen_backup_file to the local Restore Directory"
        elif [[ "$restorefull" == [rR] ]] || [[ "$restoresingle" == [rR] ]]; then
            if [[ "$remote_server" == "1" ]]; then
                local result=$(sudo sshpass -p "$CFG_BACKUP_REMOTE_1_PASS" scp -o StrictHostKeyChecking=no "$CFG_BACKUP_REMOTE_1_USER"@"$CFG_BACKUP_REMOTE_1_IP":"$remote_path_save/$chosen_backup_file" "$destination_path" | pv -p -e -r > /dev/null)
                checkSuccess "Copy $chosen_backup_file from $CFG_BACKUP_REMOTE_1_IP to $RESTORE_SAVE_DIRECTORY"
            elif [[ "$remote_server" == "2" ]]; then
                local result=$(sudo sshpass -p "$CFG_BACKUP_REMOTE_2_PASS" scp -o StrictHostKeyChecking=no "$CFG_BACKUP_REMOTE_2_USER"@"$CFG_BACKUP_REMOTE_2_IP":"$remote_path_save/$chosen_backup_file" "$destination_path" | pv -p -e -r > /dev/null)
                checkSuccess "Copy $chosen_backup_file from $CFG_BACKUP_REMOTE_2_IP to $RESTORE_SAVE_DIRECTORY"
            fi
        fi
    fi
}
