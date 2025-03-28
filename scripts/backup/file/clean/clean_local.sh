#!/bin/bash

# Local backup cleanup function
clean_local_backups() 
{
    local backup_location="$1"
    local date_format="20[0-9][0-9]-[0-1][0-9]-[0-3][0-9]"  # Format for the date in folder name

    # List local backup folders and sort by date
    local result=$(sudo find "$backup_location" -maxdepth 1 -type d -name "backup-*" | sort)

    isNotice "Cleaning of old folders now starting for local backups..."

    while read -r folder_name; do
        if [[ $folder_name =~ backup-($date_format) ]]; then
            local folder_date="${BASH_REMATCH[1]}"
            local folder_age_in_days=$(( ( $(date +%s) - $(date -d "$folder_date" +%s) ) / 86400 ))

            if [ "$folder_age_in_days" -gt "$CFG_BACKUP_KEEPDAYS" ]; then
                result=$(sudo rm -rf "$folder_name")
                checkSuccess "Removed local folder: $folder_name"
            fi
        fi
    done <<< "$result"
}