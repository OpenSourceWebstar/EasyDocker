#!/bin/bash

backupStart()
{
    local app_name="$1"
    local stored_app_name=$app_name
    local backup_file_name="$CFG_INSTALL_NAME-$app_name-backup-$backupDate"
    if [ "$app_name" == "full" ]; then
        local backup_save_directory="$backup_full_dir"
    elif [ "$app_name" != "full" ]; then
        local backup_save_directory="$backup_single_dir"
    fi

    # Safeguarding
    if [ "$app_name" == "" ]; then
        isNotice "Empty app_name, something went wrong"
        exit
    fi

    echo ""
    echo "##########################################"
    echo "###      Backing up $stored_app_name"
    echo "##########################################"
    echo ""

	((menu_number++))
    echo ""
    echo "---- $menu_number. Checking exisiting backup files"
    echo ""

    backupExistsCheck $app_name $backup_file_name $backup_save_directory;

	((menu_number++))
    echo ""
    echo "---- $menu_number. Shutting container(s) for backup"
    echo ""

    if [ "$stored_app_name" == "full" ]; then
        dockerStopAllApps;
    else
        dockerComposeDown $stored_app_name;
    fi

	((menu_number++))
    echo ""
    echo "---- $menu_number. Backing up $stored_app_name docker folder"
    echo ""

    backupZipFile $app_name $backup_file_name $backup_save_directory;

	((menu_number++))
    echo ""
    echo "---- $menu_number. Starting up all docker containers"
    echo ""

    if [ "$stored_app_name" == "full" ]; then
        dockerStartAllApps;
    else
        dockerStartApp $stored_app_name;
    fi

    if [ "$CFG_BACKUP_REMOTE_1_ENABLED" == "true" ] || [ "$CFG_BACKUP_REMOTE_2_ENABLED" == "true" ]; then

	    ((menu_number++))
        echo ""
        echo "---- $menu_number. Transfering backup file to remote server(s)"
        echo ""

        backupFindLatestFile $stored_app_name;
    fi

	((menu_number++))
    echo ""
    echo "---- $menu_number. Logging backup into database"
    echo ""

    databaseBackupInsert $stored_app_name;

	((menu_number++))
    echo ""
    echo "---- $menu_number. Cleaning old backup files"
    echo ""

    backupCleanFiles;

	((menu_number++))
    echo ""
    echo "A backup of the $stored_app_name docker folder has been taken on $current_date at $current_time!" >> $logs_dir$backup_log_file
    echo ""

	menu_number=0
    backupsingle=n
    backupfull=n
    cd
}
