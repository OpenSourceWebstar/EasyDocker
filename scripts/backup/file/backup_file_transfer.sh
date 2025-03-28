#!/bin/bash

backupTransferFile()
{
    local app_name="$1"
    local latest_backup_file="$2"

    # Safeguarding
    if [ "$app_name" == "" ]; then
        isNotice "Empty app_name, something went wrong"
        exit
    fi

    if [ "$CFG_BACKUP_REMOTE_1_ENABLED" == "true" ]; then
        local backup_location_1="$CFG_BACKUP_REMOTE_1_BACKUP_DIRECTORY/$backup_remote_directory"
        local backup_location_clean_1="$(echo "$backup_location_1" | sed 's/\/\//\//g')"
        isNotice "Remote backup 1 enabled, transferring file: $latest_backup_file"
        
        if [ "$CFG_BACKUP_REMOTE_1_TYPE" == "SSH" ]; then
            if ssh -o ConnectTimeout=10 "$CFG_BACKUP_REMOTE_1_USER"@"$CFG_BACKUP_REMOTE_1_IP" true; then
                checkSuccess "SSH connection to $CFG_BACKUP_REMOTE_1_IP is established."

                # Get file size
                local file_size=$(stat -c %s "$latest_backup_file")

                # Use pv to show progress while transferring the file
                local result=$(pv -s "$file_size" "$latest_backup_file" | sudo scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
                    "$latest_backup_file" "$CFG_BACKUP_REMOTE_1_USER@$CFG_BACKUP_REMOTE_1_IP:$backup_location_clean_1")

                checkSuccess "Transferring $app_name backup to Remote Backup Host 1 - $CFG_BACKUP_REMOTE_1_IP"
            else
                checkSuccess "Unable to connect to SSH for $CFG_BACKUP_REMOTE_1_IP"
            fi
        elif [ "$CFG_BACKUP_REMOTE_1_TYPE" == "LOGIN" ]; then
            if sshRemote "$CFG_BACKUP_REMOTE_1_PASS" $CFG_BACKUP_REMOTE_1_PORT "$CFG_BACKUP_REMOTE_1_USER@$CFG_BACKUP_REMOTE_1_IP" "mkdir -p \"$backup_location_clean_1\""; then
                isSuccessful "Creating remote folders"
                isNotice "Transfer of $app_name to $CFG_BACKUP_REMOTE_1_IP. Please wait... it may take a while..."

                # Get file size
                local file_size=$(stat -c %s "$latest_backup_file")

                # Use pv to show progress with sshpass
                local result=$(pv -s "$file_size" "$latest_backup_file" | sudo sshpass -p "$CFG_BACKUP_REMOTE_1_PASS" scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
                    "$latest_backup_file" "$CFG_BACKUP_REMOTE_1_USER@$CFG_BACKUP_REMOTE_1_IP:$backup_location_clean_1")

                if [ $? -eq 0 ]; then
                    isSuccessful "Transferring $app_name backup to Remote Backup Host 1 - $CFG_BACKUP_REMOTE_1_IP"
                else
                    isError "SCP failed to upload file to $backup_location_clean_1"
                fi
            else
                isError "SSH connection to $CFG_BACKUP_REMOTE_1_IP failed."
            fi
        fi
    fi

    if [ "$CFG_BACKUP_REMOTE_2_ENABLED" == "true" ]; then
        local backup_location_2="$CFG_BACKUP_REMOTE_2_BACKUP_DIRECTORY/$backup_remote_directory"
        local backup_location_clean_2="$(echo "$backup_location_2" | sed 's/\/\//\//g')"
        isNotice "Remote backup 2 enabled, transferring file: $latest_backup_file"
        
        if [ "$CFG_BACKUP_REMOTE_2_TYPE" == "SSH" ]; then
            if ssh -o ConnectTimeout=10 "$CFG_BACKUP_REMOTE_2_USER"@"$CFG_BACKUP_REMOTE_2_IP" true; then
                checkSuccess "SSH connection to $CFG_BACKUP_REMOTE_2_IP is established."

                # Get file size
                local file_size=$(stat -c %s "$latest_backup_file")

                # Use pv to show progress while transferring the file
                local result=$(pv -s "$file_size" "$latest_backup_file" | sudo scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
                    "$latest_backup_file" "$CFG_BACKUP_REMOTE_2_USER@$CFG_BACKUP_REMOTE_2_IP:$backup_location_clean_2")

                checkSuccess "Transferring $app_name backup to Remote Backup Host 2 - $CFG_BACKUP_REMOTE_2_IP"
            else
                checkSuccess "Unable to connect to SSH for $CFG_BACKUP_REMOTE_2_IP"
            fi
        elif [ "$CFG_BACKUP_REMOTE_2_TYPE" == "LOGIN" ]; then
            if sshRemote "$CFG_BACKUP_REMOTE_2_PASS" $CFG_BACKUP_REMOTE_2_PORT "$CFG_BACKUP_REMOTE_2_USER@$CFG_BACKUP_REMOTE_2_IP" "mkdir -p \"$backup_location_clean_2\""; then
                isSuccessful "Creating remote folders"
                isNotice "Transfer of $app_name to $CFG_BACKUP_REMOTE_2_IP. Please wait... it may take a while..."

                # Get file size
                local file_size=$(stat -c %s "$latest_backup_file")

                # Use pv to show progress with sshpass
                local result=$(pv -s "$file_size" "$latest_backup_file" | sudo sshpass -p "$CFG_BACKUP_REMOTE_2_PASS" scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
                    "$latest_backup_file" "$CFG_BACKUP_REMOTE_2_USER@$CFG_BACKUP_REMOTE_2_IP:$backup_location_clean_2")

                if [ $? -eq 0 ]; then
                    isSuccessful "Transferring $app_name backup to Remote Backup Host 2 - $CFG_BACKUP_REMOTE_2_IP"
                else
                    isError "SCP failed to upload file to $backup_location_clean_2"
                fi
            else
                isError "SSH connection to $CFG_BACKUP_REMOTE_2_IP failed."
            fi
        fi
    fi
}
