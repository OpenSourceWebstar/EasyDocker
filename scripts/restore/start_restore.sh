#!/bin/bash

restoreStart()
{
    local app_name="$1"
    local stored_app_name=$app_name
    local chosen_backup_file="$2"
    local remote_path="$3"
    local remote_path_clean="$(echo "$remote_path" | sed 's/\/\//\//g')"

    # Safeguarding restores
    if [[ $stored_app_name == "" ]]; then
        isError "No app_name provided, unable to start restore."
        return 1
    fi

    echo ""
    echo "##########################################"
    echo "###      Restoring $stored_app_name Docker Folder"
    echo "##########################################"
    echo ""

    portClearAllData;

    ((menu_number++))
    echo ""
    echo "---- $menu_number. Setting up install folder and config file for $app_name."
    echo ""

    dockerConfigSetupToContainer "loud" "$stored_app_name" "install";
    isSuccessful "Install folders and Config files have been setup for $stored_app_name."

    ((menu_number++))
    echo ""
    echo "---- $menu_number. Setting up install variables for $app_name."
    echo ""

    setupInstallVariables $stored_app_name;

    ((menu_number++))
    echo ""
    echo "---- $menu_number. Shutting Down container(s) for restoration"
    echo ""

    dockerComposeDown $stored_app_name;

    ((menu_number++))
    echo ""
    echo "---- $menu_number. Getting backup file to restore"
    echo ""

    restoreCopyFile "$remote_path_clean";

    ((menu_number++))
    echo ""
    echo "---- $menu_number. Removing old folder(s)"
    echo ""

    restoreDeleteDockerFolder;

    ((menu_number++))
    echo ""
    echo "---- $menu_number. Extracting from backup file"
    echo ""

    restoreExtractFile;

    if [[ "$restoresingle" == [mM] ]]; then
        ((menu_number++))
        echo ""
        echo "---- $menu_number. Running migration scans to update the files before install."
        echo ""

        migrateGenerateTXTAll;
        migrateScanFoldersForUpdates;
        migrateUpdateFiles $stored_app_name;
    fi

    ((menu_number++))
    echo ""
    echo "---- $menu_number. Checking & Opening ports if required"
    echo ""

    portsCheckApp $app_name install;
    if [[ $disallow_used_port == "true" ]]; then
        isError "A used port conflict has occured, setup is cancelling..."
        disallow_used_port=""
        return
    else
        isSuccessful "No used port conflicts found, setup is continuing..."
    fi
    if [[ $disallow_open_port == "true" ]]; then
        isError "An open port conflict has occured, setup is cancelling..."
        disallow_open_port=""
        return
    else
        isSuccessful "No open port conflicts found, setup is continuing..."
    fi
        
    ((menu_number++))
    echo ""
    echo "---- $menu_number. Updating docker-compose file(s)"
    echo ""

    dockerComposeUpdateAndStartApp $stored_app_name install;

    ((menu_number++))
    echo ""
    echo "---- $menu_number. Updating file permissions before starting."
    echo ""

    fixPermissionsBeforeStart $stored_app_name;

    ((menu_number++))
    echo ""
    echo "---- $menu_number. Starting up the $stored_app_name docker service(s)"
    echo ""

    dockerComposeUp $stored_app_name;

    ((menu_number++))
    echo ""
    echo "---- $menu_number. Logging backup into database"
    echo ""

    databaseRestoreInsert $stored_app_name;

    ((menu_number++))
    echo ""
    echo "---- $menu_number. Adding $stored_app_name to the Apps Database table."
    echo ""

    databaseInstallApp $stored_app_name;

    ((menu_number++))
    echo ""
    echo "---- $menu_number. Running Headscale setup (if required)"
    echo ""

    setupHeadscale $stored_app_name;

    ((menu_number++))
    echo ""
    echo "---- $menu_number. Running Application specific updates (if required)"
    echo ""

    appUpdateSpecifics $stored_app_name;

    ((menu_number++))
    echo ""
    echo "---- $menu_number. Cleaning files used to restore"
    echo ""

    restoreCleanFiles;

    if [[ "$restoresingle" == [mM] ]]; then
        ((menu_number++))
        echo ""
        echo "---- $menu_number. Moving installed backup file to Migration storage."
        echo ""

        migrateRestoreFileMoveToMigrate $stored_app_name $chosen_backup_file;
    fi

    ((menu_number++))
    echo ""
    echo "    A $stored_app_name backup has been restored!"
    echo ""
    
    menu_number=0
    backupsingle=n
    restoresingle=n

    if [[ "$restoresingle" == [mM] ]]; then
        migrateCheckForMigrateFiles;
    else
        return
    fi
    
    cd
}
