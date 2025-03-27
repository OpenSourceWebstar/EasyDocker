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

    local result=$(cd $containers_dir && zipFile "$CFG_BACKUP_PASSPHRASE" "$backup_save_directory/$backup_file_name.zip" "$app_name")
    checkSuccess "Compressing $app_name folder into an encrypted zip file"

}
