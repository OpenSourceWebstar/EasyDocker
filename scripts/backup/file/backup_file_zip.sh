#!/bin/bash

backupZipFile()
{
    local app_name="$1"
    local backup_file_name="$2"
    local backup_save_directory="$3"

    # Safeguarding
    if [ "$app_name" == "" ]; then
        isNotice "Empty app_name, something went wrong"
        exit
    fi

    isNotice "The new Backup file will be named : ${backup_file_name}.zip"
    local result=$(createFolders "loud" $docker_install_user $backup_save_directory)
    checkSuccess "Creating Backup folder in case it doesn't exist"
    isNotice "Starting Compression, this may take a while"
    if [ "$app_name" == "full" ]; then
        # Create a temporary directory
        local temp_dir=$(mktemp -d)

        local result=$(createFolders "loud" $docker_install_user "$temp_dir/$(basename "$docker_dir")")
        checkSuccess "Create the $docker_dir inside the temporary directory"

        local result=$(cd $docker_dir && sudo cp -r --parents database.db containers/ ssl/ install/configs/ "$temp_dir/$(basename "$docker_dir")")
        checkSuccess "Copy the data to the temporary directory"

        local result=$(cd "$temp_dir" && zipFile "$CFG_BACKUP_PASSPHRASE" "$backup_save_directory/$backup_file_name.zip" "$(basename "$docker_dir")")
        checkSuccess "Create the zip command to include duplicates in the zip file"

        local result=$(sudo rm -r "$temp_dir")
        checkSuccess "Remove the temporary directory"

        #checkSuccess "Compressing $app_name folder into an encrypted zip file"
    elif [ "$app_name" != "full" ]; then
        local result=$(cd $containers_dir && zipFile "$CFG_BACKUP_PASSPHRASE" "$backup_save_directory/$backup_file_name.zip" "$app_name")
        checkSuccess "Compressing $app_name folder into an encrypted zip file"
    fi
}
