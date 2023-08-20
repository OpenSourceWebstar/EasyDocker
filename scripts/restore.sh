#!/bin/bash

app_name="$1"
chosen_backup_file="$2"

restoreStart()
{
    local app_name="$1"
    local chosen_backup_file="$2"

    echo ""
    echo "##########################################"
    echo "###      Restoring $app_name Docker Folder"
    echo "##########################################"
    echo ""

	((menu_number++))
    echo ""
    echo "---- $menu_number. Shutting Down container(s) for restoration"
    echo ""

    if [ "$app_name" == "full" ]; then
        dockerStopAllApps;
    else
        dockerAppDown;
    fi

	((menu_number++))
    echo ""
    echo "---- $menu_number. Getting backup file to restore"
    echo ""

    restoreCopyFile;

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
    
	((menu_number++))
    echo ""
    echo "---- $menu_number. Starting up the $app_name docker service(s)"
    echo ""

    if [ "$app_name" == "full" ]; then
        dockerStartAllApps;
    else
        dockerAppUp;
    fi

	((menu_number++))
    echo ""
    echo "---- $menu_number. Cleaning files used to restore"
    echo ""

    restoreCleanFiles;

	((menu_number++))
    echo ""
    echo "---- $menu_number. Logging backup into database"
    echo ""

    databaseRestoreInsert;

	((menu_number++))
    echo ""
    echo "    A $app_name backup has been restored!"
    echo ""
    
    menu_number=0
    backupsingle=n
    backupfull=n
    restoresingle=n
    restorefull=n
    mainMenu;
    cd
}

restoreSingleBackupList()
{
    if [[ "$restoresingle" == [lL] ]]; then
        # Function to display a numbered list of app_names (zip files)
        select_app() {
            echo ""
            echo "##########################################"
            echo "###       Single App Restore List"
            echo "##########################################"
            echo ""
            app_list=()
            local count=1
            for zip_file in "$BACKUP_SAVE_DIRECTORY"/*.zip; do
                if [ -f "$zip_file" ]; then
                    # Extract the app_name from the filename using sed
                    app_name=$(basename "$zip_file" | sed -E 's/.*-([^-]+)-backup-.*/\1/')
                    app_list+=("$app_name")
                    isOption "$count. $app_name"
                    ((count++))
                fi
            done
        }

        # Function to display a numbered list of backup files for a selected app_name
        select_backup_file() {
            selected_app=$1
            echo ""
            echo "##########################################"
            echo "###  Available backups for $selected_app:"
            echo "##########################################"
            echo ""
            backup_list=()
            local count=1
            for zip_file in "$BACKUP_SAVE_DIRECTORY"/*-$selected_app-backup-*; do
                if [ -f "$zip_file" ]; then
                    backup_list+=("$zip_file")
                    isOption "$count. $(basename "$zip_file")"
                    ((count++))
                fi
            done
        }

        # Main script starts here
        select_app

        # Read the user's choice number for app_name
        echo ""
        isQuestion "Select an application (number): "
        read -p "" chosen_app_number

        # Validate the user's choice number
        if [[ "$chosen_app_number" =~ ^[0-9]+$ ]]; then
            selected_app_index=$((chosen_app_number - 1))

            if [ "$selected_app_index" -ge 0 ] && [ "$selected_app_index" -lt "${#app_list[@]}" ]; then
                selected_app_name="${app_list[selected_app_index]}"
                select_backup_file "$selected_app_name"

                # Read the user's choice number for backup file
                echo ""
                isQuestion "Select a backup file (number): "
                read -p "" chosen_backup_number

                # Validate the user's choice number for backup file
                if [[ "$chosen_backup_number" =~ ^[0-9]+$ ]]; then
                    selected_backup_index=$((chosen_backup_number - 1))

                    if [ "$selected_backup_index" -ge 0 ] && [ "$selected_backup_index" -lt "${#backup_list[@]}" ]; then
                        chosen_backup_file=$(basename "${backup_list[selected_backup_index]}")
                        echo ""
                        isNotice "You selected: $chosen_backup_file"
                        restoreStart $selected_app_name $chosen_backup_file
                    else
                        echo ""
                        isNotice "Invalid backup file selection."
                    fi
                else
                    echo ""
                    isNotice "Invalid input for backup file selection."
                fi
            else
                echo ""
                isNotice "Invalid application selection."
            fi
        else
            echo "" 
            isNotice "Invalid input for application selection."
        fi
    fi
}

restoreFullBackupList() 
{
    if [[ "$restorefull" == [lL] ]]; then
        # Function to display a numbered list of backup files in the single folder
        select_backup_file() {
            echo ""
            echo "##########################################"
            echo "###     Available Full Backup Files"
            echo "##########################################"
            echo ""
            backup_list=()
            local count=1
            for zip_file in "$BACKUP_SAVE_DIRECTORY"/*.zip; do
                if [ -f "$zip_file" ]; then
                    backup_list+=("$zip_file")
                    isOption "$count. $(basename "$zip_file")"
                    ((count++))
                fi
            done
            if [ "${#backup_list[@]}" -eq 0 ]; then
                echo ""
                isNotice "No backup files found in $BACKUP_SAVE_DIRECTORY."
                return 1
            fi
        }

        # Main script starts here
        select_backup_file || return 1

        # Read the user's choice number for backup file
        echo ""
        isQuestion "Select a backup file (number): "
        read -p "" chosen_backup_number

        # Validate the user's choice number for backup file
        if [[ "$chosen_backup_number" =~ ^[0-9]+$ ]]; then
            selected_backup_index=$((chosen_backup_number - 1))

            if [ "$selected_backup_index" -ge 0 ] && [ "$selected_backup_index" -lt "${#backup_list[@]}" ]; then
                chosen_backup_file=$(basename "${backup_list[selected_backup_index]}")
                selected_app_name=full
                echo ""
                isNotice "You selected: $chosen_backup_file"
                restoreStart $selected_app_name $chosen_backup_file
            else
                echo ""
                isNotice "Invalid backup file selection."
            fi
        else
            echo ""
            isNotice "Invalid input for backup file selection."
        fi
    elif [[ "$restorefull" == [rR] ]]; then
        # SSH command to list backup files on the remote host
        remote_backup_list=$(ssh "$CFG_RESTORE_REMOTE_USER"@"$CFG_RESTORE_REMOTE_IP" "ls -1 \"$CFG_BACKUP_REMOTE_BACKUP_DIRECTORY\"/*.zip 2>/dev/null")

        # Function to display a numbered list of backup files from the remote host
        select_remote_backup_file() {
            echo ""
            echo "##########################################"
            echo "###   Available Full Backup Files (Remote)"
            echo "##########################################"
            echo ""
            remote_backup_list=()
            local count=1
            while IFS= read -r remote_backup_file; do
                if [ -n "$remote_backup_file" ]; then
                    remote_backup_list+=("$remote_backup_file")
                    isOption "$count. $(basename "$remote_backup_file")"
                    ((count++))
                fi
            done <<< "$remote_backup_list"
            if [ "${#remote_backup_list[@]}" -eq 0 ]; then
                echo ""
                isNotice "No backup files found on the remote host."
                return 1
            fi
        }

        # Main script starts here
        select_remote_backup_file || return 1

        # Read the user's choice number for backup file
        echo ""
        isQuestion "Select a backup file (number): "
        read -p "" chosen_backup_number

        # Validate the user's choice number for backup file
        if [[ "$chosen_backup_number" =~ ^[0-9]+$ ]]; then
            selected_backup_index=$((chosen_backup_number - 1))

            if [ "$selected_backup_index" -ge 0 ] && [ "$selected_backup_index" -lt "${#remote_backup_list[@]}" ]; then
                chosen_backup_file=$(basename "${remote_backup_list[selected_backup_index]}")
                echo ""
                isNotice "You selected: $chosen_backup_file"
                restoreStart $selected_app_name $chosen_backup_file
            else
                echo ""
                isNotice "Invalid backup file selection."
            fi
        else
            echo ""
            isNotice "Invalid input for backup file selection."
        fi
    fi
}

restoreCopyFile()
{
    if [[ "$restorefull" == [lL] ]] || [[ "$restoresingle" == [lL] ]]; then
        # Extract the date from the filename using sed (assuming the date format is YYYY-MM-DD)
        RestoreBackupDate=$(echo "$chosen_backup_file" | sed -E 's/.*-([0-9]{4}-[0-9]{2}-[0-9]{2})\.zip/\1/')
        isNotice "The Latest Backup file is $chosen_backup_file, using this for restore."
        result=$(cp "$BACKUP_SAVE_DIRECTORY/$chosen_backup_file" "$RESTORE_SAVE_DIRECTORY")
        checkSuccess "Copying over $chosen_backup_file to the local Restore Directory"
    elif [[ "$restorefull" == [rR] ]] || [[ "$restoresingle" == [rR] ]]; then
        # Extract the date from the filename (assuming the date format is YYYY-MM-DD)
        RestoreBackupDate=$(echo "$chosen_backup_file" | cut -d'-' -f1-3)
        isNotice "The Latest Backup file is $chosen_backup_file, using this for restore."
        # Copy the latest file from the remote host to the local restore_dir
        result=$(scp "$CFG_RESTORE_CFG_RESTORE_REMOTE_USER"@"$CFG_RESTORE_REMOTE_IP":"$CFG_BACKUP_REMOTE_BACKUP_DIRECTORY/$chosen_backup_file" "$RESTORE_SAVE_DIRECTORY")
        checkSuccess "Copy $chosen_backup_file from $CFG_RESTORE_REMOTE_IP locally to $CFG_BACKUP_REMOTE_BACKUP_DIRECTORY"
    fi
}

restoreDeleteDockerFolder()
{
    if [[ "$restorefull" == [lLrR] ]]; then
        # Folders to exclude (separated by spaces)
        exclude_folders=("install" "backups" "restore")
        # Loop through the exclude_folders array and construct the --exclude options
        exclude_options=""
        for folder in "${exclude_folders[@]}"; do
            exclude_options+=" --exclude='$folder'"
        done
        # Run rsync command to delete everything in base_dir except the specified folders
        result=$(sudo rsync -a --delete $exclude_options "$base_dir/" "$base_dir")
        checkSuccess "Deleting the $app_name Docker install folder $base_dir"
    else
        result=$(sudo rm -rf $install_path$app_name)
        checkSuccess "Deleting the $app_name Docker install folder in $install_path$app_name"
    fi
}

restoreExtractFile()
{
    if [[ "$restorefull" == [lLrR] ]]; then
        cd $RESTORE_SAVE_DIRECTORY
        # Local
        if [[ "$restorefull" == [lL] ]]; then
            result=$(unzip -o -P $CFG_BACKUP_PASSPHRASE $chosen_backup_file -d /)
            checkSuccess "Decrypting $chosen_backup_file (Local)"
        fi
        # Remote
        if [[ "$restorefull" == [rR] ]]; then
            result=$(unzip -o -P $CFG_RESTORE_REMOTE_BACKUP_PASSPHRASE $chosen_backup_file -d /)
            checkSuccess "Decrypting $chosen_backup_file (Remote)"
        fi
    else
        cd $RESTORE_SAVE_DIRECTORY
        # Local
        if [[ "$restoresingle" == [lL] ]]; then
            unzip -o -P $CFG_BACKUP_PASSPHRASE $chosen_backup_file -d $install_path
            checkSuccess "Decrypting $chosen_backup_file (Local)"
        fi
        # Remote
        if [[ "$restoresingle" == [rR] ]]; then
            result=$(unzip -o -P $CFG_RESTORE_REMOTE_BACKUP_PASSPHRASE $chosen_backup_file -d $install_path)
            checkSuccess "Decrypting $chosen_backup_file (Remote)"
        fi
    fi
}

restoreCleanFiles()
{
    if [[ "$restorefull" == [lLrR] ]]; then
        result=$(rm -rf $RESTORE_SAVE_DIRECTORY/*.zip)
        checkSuccess "Clearing unneeded restore data"
    else
        result=$(rm -rf $RESTORE_SAVE_DIRECTORY/*.zip)
        checkSuccess "Clearing unneeded restore data"
    fi
}

restoreInitialize()
{
    if [[ "$restorefull" == [lLrR] ]]; then
        local app_name="$1"
        app_name="full"
        BACKUP_SAVE_DIRECTORY="$backup_full_dir"
        RESTORE_SAVE_DIRECTORY="$restore_full_dir"
	    restoreFullBackupList;
    else
        BACKUP_SAVE_DIRECTORY="$backup_single_dir"
        RESTORE_SAVE_DIRECTORY="$restore_single_dir"
        restoreSingleBackupList;
    fi
}