#!/bin/bash

restoreDeleteDockerFolder()
{
    if [[ "$restorefull" == [lLrRmM] ]]; then
        # Folders to exclude (separated by spaces)
        exclude_folders=("install" "backups" "restore")
        # Loop through the exclude_folders array and construct the --exclude options
        exclude_options=""
        for folder in "${exclude_folders[@]}"; do
            exclude_options+=" --exclude='$folder'"
        done
        # Run rsync command to delete everything in docker_dir except the specified folders
        local result=$(sudo rsync -a --delete $exclude_options "$docker_dir/" "$docker_dir")
        checkSuccess "Deleting the $app_name Docker install folder $docker_dir"
    elif [[ "$restoresingle" == [lLrRmM] ]]; then
        local result=$(sudo rm -rf $containers_dir$app_name)
        checkSuccess "Deleting the $app_name Docker install folder in $containers_dir$app_name"
    fi
}

restoreCleanFiles()
{
    if [[ "$restorefull" == [lLrRmM] ]]; then
        local result=$(sudo rm -rf $RESTORE_SAVE_DIRECTORY/*.zip)
        checkSuccess "Clearing unneeded restore data"
    elif [[ "$restoresingle" == [lLrRmM] ]]; then
        local result=$(sudo rm -rf $RESTORE_SAVE_DIRECTORY/*.zip)
        checkSuccess "Clearing unneeded restore data"
    fi
}
