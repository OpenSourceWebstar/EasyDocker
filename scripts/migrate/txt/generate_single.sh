#!/bin/bash

migrateGenerateTXTSingle()
{
    local app_name=$1
    local migrate_file_path="$containers_dir/$app_name/$migrate_file"
    # Check if the specified directory exists
    if [ -d "$containers_dir/$app_name" ]; then
        # Check if a migrate.txt file already exists in the specified directory
        if [ ! -f "$migrate_file_path" ]; then
            migrateBuildTXT $app_name;
        else
            isNotice "$migrate_file already exists for $app_name."
            while true; do
                isQuestion "Do you want to update $migrate_file to the local machine? (y/n): "
                read -rp "" replacemigration
                if [[ "$replacemigration" =~ ^[yYnN]$ ]]; then
                    break
                fi
                isNotice "Please provide a valid input (y/n)."
            done
            if [[ "$replacemigration" == [yY] ]]; then
                migrateBuildTXT $app_name;
            fi
        fi
    else
        isNotice "The specified directory $app_name does not exist."
    fi
    
    isSuccessful "Generating $migrate_file for $app_name completed."
}
