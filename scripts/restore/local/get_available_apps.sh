#!/bin/bash

# Function to collect available backups and list unique applications
getAvailableLocalApps() 
{
    local -n app_list_ref=$1
    declare -A seen_apps  # Use an associative array to track unique app names

    for zip_file in "$backup_save_directory"/*.zip; do
        if [[ -f "$zip_file" ]]; then
            local app_name
            app_name=$(basename "$zip_file" | sed -E 's/.*-([^-]+)-backup-.*/\1/')

            if [[ -z "${seen_apps[$app_name]}" ]]; then
                app_list_ref+=("$app_name")
                seen_apps[$app_name]=1
            fi
        fi
    done
}