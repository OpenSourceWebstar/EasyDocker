#!/bin/bash

migrateGenerateTXTAll()
{
    echo ""
    echo "############################################"
    echo "######       Migration Install        ######"
    echo "############################################"
    echo ""

    local migrate_file_path="$containers_dir/$app_name/$migrate_file"

    # Loop through subdirectories
    for folder in "$containers_dir"/*; do
        # Extract the folder name from the full path
        local app_name=$(basename "$folder")
        if [ -d "$containers_dir/$app_name" ]; then

            # Check if a migrate.txt file exists in the current directory
            if [ ! -f "$migrate_file_path" ]; then
                migrateBuildTXT $app_name;
            fi
        fi
    done
    
    isSuccessful "Scanning and creating migrate.txt files completed."
}
