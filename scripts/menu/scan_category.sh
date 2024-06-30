#!/bin/bash

scanCategory() 
{
    local category="$1"
    local app_found=false

    for app_dir in "$install_containers_dir"/*/; do
        local app_name=$(basename "$app_dir")
        local app_file="$app_dir$app_name.sh"
        
        if [ -f "$app_file" ]; then
            local category_info=$(grep -Po '(?<=# Category : ).*' "$app_file")
            
            if [ "$category_info" == "$category" ]; then
                app_found=true
                local app_description=$(grep -Po '(?<=# Description : ).*' "$app_file")

                # Query the database to check if the app is installed
                results=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT name FROM apps WHERE status = 1 AND name = '$app_name';")
                if [[ -n "$results" ]]; then
                    local app_description="\e[32m*INSTALLED*\e[0m - $app_description"
                else
                    local app_description="\e[33m*NOT INSTALLED*\e[0m - $app_description"
                fi

                isOptionMenu "$app_description "
                read -rp "" $app_name
            fi
        fi
    done

    if [ "$app_found" = false ]; then
        isNotice "No applications found under the category: $category"
    fi
}