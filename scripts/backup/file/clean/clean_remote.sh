#!/bin/bash

# Remote backup cleanup function
clean_remote_backups() 
{
    local remote_ip="$1"
    local remote_user="$2"
    local remote_pass="$3"
    local remote_port="$4"
    local backup_directory="$5"
    local keep_days="$6"

    # Clean up remote backups
    local backup_location_clean="$(echo "$backup_directory" | sed 's/\/\//\//g')"
    local date_format="20[0-9][0-9]-[0-1][0-9]-[0-3][0-9]"

    isNotice "Cleaning of old folders now starting for remote backup on $remote_ip"

    # List all folders in the remote backup directory
    local result=$(sshRemote "$remote_pass" "$remote_port" "$remote_user" "$remote_ip" "ls -d $backup_location_clean/backup-*")

    while read -r folder_name; do
        if [[ $folder_name =~ backup-($date_format) ]]; then
            local folder_date="${BASH_REMATCH[1]}"
            local folder_age_in_days=$(( ( $(date +%s) - $(date -d "$folder_date" +%s) ) / 86400 ))

            if [ "$folder_age_in_days" -gt "$keep_days" ]; then
                sshRemote "$remote_pass" "$remote_port" "$remote_user" "$remote_ip" "rm -rf $folder_name"
                isSuccessful "Removed remote folder: $folder_name"
            fi
        fi
    done <<< "$result"

    isSuccessful "Removed all remote folders older than $keep_days days"
}