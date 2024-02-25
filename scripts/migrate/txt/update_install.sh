#!/bin/bash

migrateCheckAndUpdateInstallName() 
{
    local app_name="$1"
    local migrate_file_path="$containers_dir/$app_name/$migrate_file"
    # Check if the migrate.txt file exists
    if [ -f "$migrate_file_path" ]; then

        local existing_migrate_install_name=$(sudo grep -o 'MIGRATE_INSTALL_NAME=.*' "$migrate_file_path" | cut -d '=' -f 2)

        if [ -z "$existing_migrate_install_name" ]; then
            # If MIGRATE_INSTALL_NAME is not found, add it to the end of the file
            local result=$(sudo echo "MIGRATE_INSTALL_NAME=$CFG_INSTALL_NAME" | sudo tee -a "$migrate_file_path" > /dev/null)
            checkSuccess "Added MIGRATE_INSTALL_NAME to $migrate_file."
        elif [ "$existing_migrate_install_name" != "$CFG_INSTALL_NAME" ]; then
            # If the existing MIGRATE_INSTALL_NAME is different, update it
            local result=$(sudo sed -i "s/MIGRATE_INSTALL_NAME=.*/MIGRATE_INSTALL_NAME=$CFG_INSTALL_NAME/" "$migrate_file_path")
            checkSuccess "Updated MIGRATE_INSTALL_NAME in $migrate_file to $CFG_INSTALL_NAME."
        #else
            #checkNotice "MIGRATE_INSTALL_NAME in $migrate_file is already set to $CFG_INSTALL_NAME."
        fi
    else
        isError "$migrate_file not found in $app_name."
    fi
}
