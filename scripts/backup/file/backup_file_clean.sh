#!/bin/bash

backupCleanFiles()
{
    # Safeguarding
    if [ "$app_name" == "" ]; then
        isNotice "Empty app_name, something went wrong"
        exit
    fi

    local result=$(sudo find "$backup_save_directory" -type f -mtime +"$CFG_BACKUP_KEEPDAYS" -delete)
    checkSuccess "Deleting Backups older than $CFG_BACKUP_KEEPDAYS days"

    if [ "$CFG_BACKUP_REMOTE_1_ENABLED" == "true" ]; then
        if [ "$CFG_BACKUP_REMOTE_1_BACKUP_CLEAN" == "true" ]; then
            local backup_folder="single"
            local backup_location="$CFG_BACKUP_REMOTE_1_BACKUP_DIRECTORY/$CFG_INSTALL_NAME/$backup_folder"
            local backup_location_clean="$(echo "$backup_location" | sed 's/\/\//\//g')"
            local date_format="20[0-9][0-9]-[0-1][0-9]-[0-3][0-9]"
            
            isNotice "Cleaning of old files now starting for $CFG_BACKUP_REMOTE_1_IP"

            # List all files in the backup location
            local result=$(sshRemote "$CFG_BACKUP_REMOTE_1_PASS" $CFG_BACKUP_REMOTE_1_PORT "$CFG_BACKUP_REMOTE_1_USER@$CFG_BACKUP_REMOTE_1_IP" "ls $backup_location_clean")

            # Loop through the list of files
            while read -r file_name; do
                # Extract the date portion from the filename using regex
                if [[ $file_name =~ ($date_format) ]]; then
                    local file_date="${BASH_REMATCH[1]}"
                    # Calculate the age of the file in days
                    local file_age_in_days=$(( ( $(date +%s) - $(date -d "$file_date" +%s) ) / 86400 ))
                    # Check if the file is older than the specified threshold
                    if [ "$file_age_in_days" -gt "$CFG_BACKUP_REMOTE_1_BACKUP_KEEPDAYS" ]; then
                        # Remove the file
                        local result=$(sshRemote "$CFG_BACKUP_REMOTE_1_PASS" $CFG_BACKUP_REMOTE_1_PORT "$CFG_BACKUP_REMOTE_1_USER@$CFG_BACKUP_REMOTE_1_IP" "rm $backup_location_clean/$file_name")
                        isSuccessful "Removed file: $file_name"
                    fi
                fi
            done <<< "$result"

            isSuccessful "Removed all files older than $CFG_BACKUP_REMOTE_1_BACKUP_KEEPDAYS days"
        fi
    fi

    if [ "$CFG_BACKUP_REMOTE_2_ENABLED" == "true" ]; then
        if [ "$CFG_BACKUP_REMOTE_2_BACKUP_CLEAN" == "true" ]; then
            local backup_folder="single"
            local backup_location="$CFG_BACKUP_REMOTE_2_BACKUP_DIRECTORY/$CFG_INSTALL_NAME/$backup_folder"
            local backup_location_clean="$(echo "$backup_location" | sed 's/\/\//\//g')"
            local date_format="20[0-9][0-9]-[0-1][0-9]-[0-3][0-9]"
            
            isNotice "Cleaning of old files now starting for $CFG_BACKUP_REMOTE_2_IP"

            # List all files in the backup location
            local result=$(sshRemote "$CFG_BACKUP_REMOTE_2_PASS" $CFG_BACKUP_REMOTE_2_PORT "$CFG_BACKUP_REMOTE_2_USER@$CFG_BACKUP_REMOTE_2_IP" "ls $backup_location_clean")

            # Loop through the list of files
            while read -r file_name; do
                # Extract the date portion from the filename using regex
                if [[ $file_name =~ ($date_format) ]]; then
                    file_date="${BASH_REMATCH[1]}"
                    # Calculate the age of the file in days
                    file_age_in_days=$(( ( $(date +%s) - $(date -d "$file_date" +%s) ) / 86400 ))
                    # Check if the file is older than the specified threshold
                    if [ "$file_age_in_days" -gt "$CFG_BACKUP_REMOTE_2_BACKUP_KEEPDAYS" ]; then
                        # Remove the file
                        local result=$(sshRemote "$CFG_BACKUP_REMOTE_2_PASS" $CFG_BACKUP_REMOTE_2_PORT "$CFG_BACKUP_REMOTE_2_USER@$CFG_BACKUP_REMOTE_2_IP" "rm $backup_location_clean/$file_name")
                        isSuccessful "Removed file: $file_name"
                    fi
                fi
            done <<< "$result"

            isSuccessful "Removed all files older than $CFG_BACKUP_REMOTE_2_BACKUP_KEEPDAYS days"
        fi
    fi
}
