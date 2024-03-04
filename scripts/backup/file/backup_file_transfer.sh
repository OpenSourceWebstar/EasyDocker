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

    if [ "$app_name" == "full" ]; then
        local backup_folder="full"
    elif [ "$app_name" != "full" ]; then
        local backup_folder="single"
    fi

    local backup_location="$CFG_BACKUP_REMOTE_1_BACKUP_DIRECTORY/$CFG_INSTALL_NAME/$backup_folder"
    local backup_location_clean="$(echo "$backup_location" | sed 's/\/\//\//g')"

    if [ "$CFG_BACKUP_REMOTE_1_ENABLED" == "true" ]; then
        isNotice "Remote backup enabled, transfering file : $latest_backup_file"
        if [ "$CFG_BACKUP_REMOTE_1_TYPE" == "SSH" ]; then
            if ssh -o ConnectTimeout=10 "$CFG_BACKUP_REMOTE_1_USER"@"$CFG_BACKUP_REMOTE_1_IP" true; then
                checkSuccess "SSH connection to $CFG_BACKUP_REMOTE_1_IP is established."
                local result=$(sudo scp -o StrictHostKeyChecking=no UserKnownHostsFile=/dev/null "$latest_backup_file" "$CFG_BACKUP_REMOTE_1_USER"@"$CFG_BACKUP_REMOTE_1_IP":"$backup_location_clean")
                checkSuccess "Transfering $app_name backup to Remote Backup Host - $CFG_BACKUP_REMOTE_1_IP"
            else
                checkSuccess "Unable to connect to SSH for $CFG_BACKUP_REMOTE_1_IP"
            fi
        elif [ "$CFG_BACKUP_REMOTE_1_TYPE" == "LOGIN" ]; then
            if sshRemote "$CFG_BACKUP_REMOTE_1_PASS" $CFG_BACKUP_REMOTE_1_PORT "$CFG_BACKUP_REMOTE_1_USER@$CFG_BACKUP_REMOTE_1_IP" "mkdir -p \"$backup_location_clean\""; then
                isSuccessful "Creating remote folders"
                isNotice "Transfer of $app_name to $CFG_BACKUP_REMOTE_1_IP. Please wait... it may take a while..."
                if sudo sshpass -p "$CFG_BACKUP_REMOTE_1_PASS" scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$latest_backup_file" "$CFG_BACKUP_REMOTE_1_USER@$CFG_BACKUP_REMOTE_1_IP:$backup_location_clean"; then
                    isSuccessful "Transferring $app_name backup to Remote Backup Host - $CFG_BACKUP_REMOTE_1_IP"
                else
                    isError "SCP failed to upload file to $backup_location_clean"
                fi
            else
                isError "SSH connection to $CFG_BACKUP_REMOTE_1_IP failed."
            fi
        fi
    fi

    if [ "$CFG_BACKUP_REMOTE_2_ENABLED" == "true" ]; then
        isNotice "Remote backup enabled, transfering file : $latest_backup_file"
        if [ "$CFG_BACKUP_REMOTE_2_TYPE" == "SSH" ]; then
            if ssh -o ConnectTimeout=10 "$CFG_BACKUP_REMOTE_2_USER"@"$CFG_BACKUP_REMOTE_2_IP" true; then
                checkSuccess "SSH connection to $CFG_BACKUP_REMOTE_2_IP is established."
                local result=$(sudo scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$latest_backup_file" "$CFG_BACKUP_REMOTE_2_USER"@"$CFG_BACKUP_REMOTE_2_IP":"$backup_location_clean")
                checkSuccess "Transfering $app_name backup to Remote Backup Host - $CFG_BACKUP_REMOTE_2_IP"
            else
                checkSuccess "Unable to connect to SSH for $CFG_BACKUP_REMOTE_2_IP"
            fi
        elif [ "$CFG_BACKUP_REMOTE_2_TYPE" == "LOGIN" ]; then
            if sshRemote "$CFG_BACKUP_REMOTE_2_PASS" $CFG_BACKUP_REMOTE_2_PORT "$CFG_BACKUP_REMOTE_2_USER@$CFG_BACKUP_REMOTE_2_IP" "mkdir -p \"$backup_location_clean\""; then
                isSuccessful "Creating remote folders"
                isNotice "Transfer of $app_name to $CFG_BACKUP_REMOTE_2_IP. Please wait... it may take a while..."
                if sudo sshpass -p "$CFG_BACKUP_REMOTE_2_PASS" scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$latest_backup_file" "$CFG_BACKUP_REMOTE_2_USER@$CFG_BACKUP_REMOTE_2_IP:$backup_location_clean"; then
                    isSuccessful "Transferring $app_name backup to Remote Backup Host - $CFG_BACKUP_REMOTE_2_IP"
                else
                    isError "SCP failed to upload file to $backup_location_clean"
                fi
            else
                isError "SSH connection to $CFG_BACKUP_REMOTE_2_IP failed."
            fi
        fi
    fi
}
