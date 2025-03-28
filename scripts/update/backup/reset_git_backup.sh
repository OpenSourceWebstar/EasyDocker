#!/bin/bash

gitFolderResetAndBackup()
{
    echo ""
    echo "#####################################"
    echo "###      Updating EasyDocker      ###"
    echo "#####################################"
    echo ""
    update_done=false

    if [ ! -d "$backup_dir/$backup_folder" ]; then
        local result=$(createFolders "loud" $sudo_user_name "$backup_dir/$backup_folder")
        checkSuccess "Create the backup folder"
    fi
    local result=$(cd $backup_dir)
    checkSuccess "Going into the backup install folder"

    local result=$(copyFolder "$configs_dir" "$backup_dir/$backup_folder" "$sudo_user_name")
    checkSuccess "Copy the configs to the backup folder"
    local result=$(copyFolder "$logs_dir" "$backup_dir/$backup_folder" "$sudo_user_name")
    checkSuccess "Copy the logs to the backup folder"
    
    gitReset;
    
    local result=$(copyFolders "$backup_dir/$backup_folder/" "$docker_dir" "$sudo_user_name")
    checkSuccess "Copy the backed up folders back into the installation directory"

    local result=$(sudo -u $sudo_user_name zip -r "$backup_dir/$backup_folder.zip" "$backup_dir/$backup_folder")
    checkSuccess "Zipping up the the backup folder for safe keeping"

    gitCleanInstallBackups;

    gitUntrackFiles;

    isSuccessful "Custom changes have been discarded successfully"
    echo ""
    isNotice "You have updated your version of EasyDocker."
    isNotice "To avoid any issues please rerun the 'easydocker'."
    echo ""
    exit
    update_done=true
}
