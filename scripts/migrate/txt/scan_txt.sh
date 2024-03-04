#!/bin/bash

migrateScanFoldersForUpdates()
{
    # Loop through all directories in the install path
    for folder in "$containers_dir"/*; do
        # Extract the folder name from the full path
        local app_name=$(basename "$folder")
        if [ -d "$containers_dir/$app_name" ]; then
            migrateSanitizeTXT $app_name;
            migrateCheckAndUpdateIP $app_name;
            migrateCheckAndUpdateInstallName $app_name;
        fi
    done
    
    isSuccessful "Migration IP checking and updating completed."
}
