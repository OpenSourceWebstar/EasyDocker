#!/bin/bash

migrateCheckAndUpdateIP() 
{
    local app_name="$1"
    local migrate_file_path="$containers_dir/$app_name/$migrate_file"

    # Check if the migrate.txt file exists
    if [ -f "$migrate_file_path" ]; then
        local migrate_ip=$(sudo grep -o 'MIGRATE_IP=.*' "$migrate_file_path" | cut -d '=' -f 2)
        
        if [ "$migrate_ip" != "$public_ip_v4" ]; then
            if ! sudo grep -q "MIGRATE_IP=" "$migrate_file_path"; then
                # Add MIGRATE_IP if it's missing
                local result=$(sudo sed -i "1s/^/MIGRATE_IP=$public_ip_v4\n/" "$migrate_file_path")
                checkSuccess "Adding missing MIGRATE_IP for $app_name : $migrate_file."
            else
                # Update MIGRATE_IP if it's already there
                local result=$(sudo sed -i "s/MIGRATE_IP=.*/MIGRATE_IP=$public_ip_v4/" "$migrate_file_path")
                checkSuccess "Updated MIGRATE_IP for $app_name : $migrate_file to $public_ip_v4."
            fi
            
            # Replace old IP with the new IP in .yml and .env files
            local result=$(sudo find "$containers_dir/$app_name" -type f \( -name "*.yml" -o -name "*.env" \) -exec sudo sed -i "s|$migrate_ip|$public_ip_v4|g" {} \;)
            checkSuccess "Replaced old IP with $public_ip_v4 in .yml and .env files in $app_name."
        fi
    else
        isError "$migrate_file not found in $app_name."
    fi
}
