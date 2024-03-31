#!/bin/bash

backupContainerFilesRestore()
{
    local app_name="$1"
    local source_folder="$containers_dir$app_name"

    if [ -d "$temp_backup_folder" ]; then
        local result=$(copyFiles "loud" "$temp_backup_folder" "$source_folder" $docker_install_user)
        checkSuccess "Copying files from temp folder to $app_name folder."
        local result=$(rm -rf "$temp_backup_folder")
        checkSuccess "Removing temp folder as no longer needed."
    fi
}


