#!/bin/bash

gitUseExistingBackup()
{
    echo ""
    echo "#####################################"
    echo "###  Installing EasyDocker Backup ###"
    echo "#####################################"
    echo ""
    local backup_file="$1"
    local backup_file_without_zip=$(basename "$backup_file" .zip)
    update_done=false
    
    local result=$(sudo unzip -o $backup_file -d $backup_dir)
    checkSuccess "Copy the configs to the backup folder"

    gitReset;
    
    local result=$(copyFolders "$backup_dir/$backup_file_without_zip/" "$docker_dir" "$sudo_user_name")
    checkSuccess "Copy the backed up folders back into the installation directory"

    gitCleanInstallBackups;

    gitUntrackFiles;

    isSuccessful "Custom changes have been discarded successfully"

    echo ""
    isNotice "You have restored the configuration files for EasyDocker."
    isNotice "To avoid any issues please rerun the 'easydocker' command."
    echo ""
    exit
    update_done=true
}
