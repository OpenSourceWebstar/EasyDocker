#!/bin/bash

app_name="$1"
chosen_backup_file="$2"

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
    elif [[ $stored_app_name == "full" ]]; then
        isNotice "You are trying to restore a full backup! This is dangerous is unintended."
        while true; do
            isQuestion "Are you sure you want to restore a full backup? (y/n): "
            read -rp "" confirmfullrestore
            if [[ "$confirmfullrestore" =~ ^[yYnN]$ ]]; then
                break
            fi
            isNotice "Please provide a valid input (y/n)."
        done
        if [[ "$confirmfullrestore" == [nN] ]]; then
            return 1
        fi
    fi

    echo ""
    echo "##########################################"
    echo "###      Restoring $stored_app_name Docker Folder"
    echo "##########################################"
    echo ""

    ((menu_number++))
    echo ""
    echo "---- $menu_number. Shutting Down container(s) for restoration"
    echo ""

    if [ "$stored_app_name" == "full" ]; then
        dockerStopAllApps;
    else
        dockerAppDown;
    fi

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

    if [[ "$restorefull" == [mM] ]] || [[ "$restoresingle" == [mM] ]]; then
        ((menu_number++))
        echo ""
        echo "---- $menu_number. Running migration scans to update the files before install."
        echo ""

        migrateGenerateTXTAll;
        migrateScanFoldersForUpdates;
        migrateScanConfigsToMigrate;
        migrateScanMigrateToConfigs;
        migrateUpdateFiles $stored_app_name;
        app_name=$stored_app_name
    fi

    ((menu_number++))
    echo ""
    echo "---- $menu_number. Updating docker-compose file(s)"
    echo ""

    # This is mostly for the updating of the socker file update
    # For checking if it's a default compose file or not
    app_dir=$(find "$containers_dir" -type d -name "$stored_app_name" -print -quit)
    app_script="$app_dir/$stored_app_name.sh"

    setupIPsAndHostnames;

    if grep -q "editComposeFileDefault" $app_script; then
        editComposeFileDefault $app_name;
    fi

    if grep -q "editComposeFileApp" $app_script; then
        editComposeFileApp $app_name;
    fi

    ((menu_number++))
    echo ""
    echo "---- $menu_number. Updating file permissions before starting."
    echo ""

    fixPermissionsBeforeStart;

    ((menu_number++))
    echo ""
    echo "---- $menu_number. Opening ports if required"
    echo ""

    openAppPorts $app_name;
    
    ((menu_number++))
    echo ""
    echo "---- $menu_number. Starting up the $stored_app_name docker service(s)"
    echo ""

    if [ "$stored_app_name" == "full" ]; then
        dockerStartAllApps;
    else
        dockerAppUp $stored_app_name;
    fi

    ((menu_number++))
    echo ""
    echo "---- $menu_number. Logging backup into database"
    echo ""

    databaseRestoreInsert $stored_app_name;

    ((menu_number++))
    echo ""
    echo "---- $menu_number. Cleaning files used to restore"
    echo ""

    restoreCleanFiles;

    if [[ "$restorefull" == [mM] ]] || [[ "$restoresingle" == [mM] ]]; then
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
    backupfull=n
    restoresingle=n
    restorefull=n

    if [[ "$restorefull" == [mM] ]] || [[ "$restoresingle" == [mM] ]]; then
        migrateCheckForMigrateFiles;
    else
        return
    fi
    
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
            declare -A seen_apps
            local count=1

            for zip_file in "$BACKUP_SAVE_DIRECTORY"/*.zip; do
                if [ -f "$zip_file" ]; then
                    # Extract the app_name from the filename using sed
                    app_name=$(basename "$zip_file" | sed -E 's/.*-([^-]+)-backup-.*/\1/')
                    
                    # Check if the app_name is already in the associative array
                    if [ -z "${seen_apps[$app_name]}" ]; then
                        app_list+=("$app_name")
                        seen_apps["$app_name"]=1  # Mark the app_name as seen
                        isOption "$count. $app_name"
                        ((count++))
                    fi
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
    elif [[ "$restoresingle" == [rR] ]]; then
        restoreRemoteMenu single
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
        restoreRemoteMenu full
    fi
}        

restoreRemoteMenu()
{
    local backup_type="$1"

    selectRemoteLocation()
    {
        while true; do
            echo ""
            isNotice "Please select a remote backup location"
            isNotice "TIP: These are defined in the config_backup file."
            echo ""
            
            # Check if Remote 1 is enabled and display accordingly
            if [ "${CFG_BACKUP_REMOTE_1_ENABLED}" == true ]; then
                isOption "1. Backup Server 1 - '$CFG_BACKUP_REMOTE_1_USER'@'$CFG_BACKUP_REMOTE_1_IP' (Enabled)"
            else
                isOption "1. Backup Server 1 (Disabled)"
            fi
            
            # Check if Remote 2 is enabled and display accordingly
            if [ "${CFG_BACKUP_REMOTE_2_ENABLED}" == true ]; then
                isOption "2. Backup Server 2 - '$CFG_BACKUP_REMOTE_2_USER'@'$CFG_BACKUP_REMOTE_2_IP' (Enabled)"
            else
                isOption "2. Backup Server 2 (Disabled)"
            fi
            
            echo ""
            isOption "x. Exit"
            echo ""
            isQuestion "Enter your choice: "
            read -rp "" select_remote

            case "$select_remote" in
                1)
                    if [ "${CFG_BACKUP_REMOTE_1_ENABLED}" == false ]; then
                        echo ""
                        isNotice "Remote Backup Server 1 is disabled. Please select another option."
                        continue
                    fi

                    remote_user="${CFG_BACKUP_REMOTE_1_USER}"
                    remote_ip="${CFG_BACKUP_REMOTE_1_IP}"
                    remote_port="${CFG_BACKUP_REMOTE_1_PORT}"
                    remote_pass="${CFG_BACKUP_REMOTE_1_PASS}"
                    remote_directory="${CFG_BACKUP_REMOTE_1_BACKUP_DIRECTORY}"
                    remote_server=1
                    ;;
                2)
                    if [ "${CFG_BACKUP_REMOTE_2_ENABLED}" == false ]; then
                        echo ""
                        isNotice "Remote Backup Server 2 is disabled. Please select another option."
                        continue
                    fi

                    remote_user="${CFG_BACKUP_REMOTE_2_USER}"
                    remote_ip="${CFG_BACKUP_REMOTE_2_IP}"
                    remote_port="${CFG_BACKUP_REMOTE_2_PORT}"
                    remote_pass="${CFG_BACKUP_REMOTE_2_PASS}"
                    remote_directory="${CFG_BACKUP_REMOTE_2_BACKUP_DIRECTORY}"
                    remote_server=2
                    ;;
                x|X)
                    isNotice "Exiting..."
                    resetToMenu;
                    ;;
                *)
                    isNotice "Invalid option. Please select a valid option."
                    continue
                    ;;
            esac

            break  # Exit the loop when a valid selection is made
        done
    }

    # Function for the Install Name selection menu
    selectInstallName() {
        while true; do
            echo ""
            isNotice "Please select the Install Name : "
            echo ""
            isOption "1. Restore using local $CFG_INSTALL_NAME"
            isOption "2. Specify a different Install Name for restoration"
            echo ""
            isOption "x. Exit"
            echo ""
            isQuestion "Enter your choice: "
            read -rp "" select_option

            case "$select_option" in
                1)
                    restore_install_name="$CFG_INSTALL_NAME"
                    echo ""
                    isNotice "Restoring using Install Name : $restore_install_name"
                    echo ""
                    ;;
                2)
                    echo ""
                    isQuestion "Enter the Install Name you would like to restore from: "
                    read -rp "" restore_install_name
                    isNotice "Restoring using Install Name :  $restore_install_name"
                    echo ""
                    ;;
                x|X)
                    isNotice "Exiting..."
                    resetToMenu;
                    ;;
                *)
                    echo ""
                    isNotice "Invalid option. Please select a valid option."
                    continue
                    ;;
            esac

            break  # Exit the loop when a valid selection is made
        done
    }

    # Call the remote backup location menu function
    selectRemoteLocation

    # Call the Install Name selection menu function
    selectInstallName

    select_app() {
        while true; do
            echo ""
            echo "##########################################"
            echo "###  $backup_type Restore List (Remote)"
            echo "##########################################"
            echo ""
            app_list=()
            seen_apps=()  # Use a regular indexed array to keep track of seen apps
            local count=1

            # Use SSH to list remote backups
            remote_backup_list=$(sshRemote "$remote_pass" "$remote_port" "${remote_user}@${remote_ip}" "ls -1 \"${remote_directory}/${restore_install_name}/$backup_type\"/*.zip 2>/dev/null")

            # Process the list of remote backup files
            while read -r zip_file; do
                # Extract the app_name from the filename using sed
                app_name=$(basename "$zip_file" | sed -E 's/.*-([^-]+)-backup-.*/\1/')

                # Check if the app_name is already in the seen_apps array
                if ! [[ " ${seen_apps[@]} " =~ " $app_name " ]]; then
                    app_list+=("$app_name")
                    seen_apps+=("$app_name")  # Add the app_name to the seen_apps array
                    isOption "$count. $app_name"
                    ((count++))
                fi
            done <<< "$remote_backup_list"

            # Add the 'x' option to go to the main menu
            isOption "x. Go to the main menu"

            # Read the user's choice number or 'x' to go to the main menu
            echo ""
            isQuestion "Select an application (number) or 'x' to go to the main menu: "
            read -p "" chosen_app_option

            if [[ "$chosen_app_option" == "x" ]]; then
                resetToMenu;  # Go back to the main menu
            elif [[ "$chosen_app_option" =~ ^[0-9]+$ ]]; then
                selected_app_index=$((chosen_app_option - 1))

                if [ "$selected_app_index" -ge 0 ] && [ "$selected_app_index" -lt "${#app_list[@]}" ]; then
                    selected_app_name="${app_list[selected_app_index]}"
                    select_backup_file "$selected_app_name"
                    return
                else
                    echo ""
                    isNotice "Invalid application selection."
                fi
            else
                echo "" 
                isNotice "Invalid input. Please select a valid option or 'x' to go to the main menu."
            fi
        done
    }

    select_backup_file() {
        selected_app=$1
        saved_selected_app=$selected_app
        echo ""
        echo "##########################################"
        echo "###    Available backups for $saved_selected_app:"
        echo "##########################################"
        echo ""
        backup_list=()
        local count=1

        # Use SSH to list remote backups for the selected app
        remote_backup_list=$(sshRemote "$remote_pass" "$remote_port" "${remote_user}@${remote_ip}" "ls -1 \"${remote_directory}/${restore_install_name}/$backup_type\"/*$saved_selected_app* 2>/dev/null")

        # Process the list of remote backup files
        while read -r zip_file; do
            backup_list+=("$zip_file")
            isOption "$count. $(basename "$zip_file")"
            ((count++))
        done <<< "$remote_backup_list"

        while true; do
            # Read the user's choice number or input
            echo ""
            isQuestion "Select a backup file (number) or 'b' to go back: "
            read -p "" chosen_backup_option

            if [[ "$chosen_backup_option" == "b" ]]; then
                select_app  # Go back to the application selection
                return
            elif [[ "$chosen_backup_option" =~ ^[0-9]+$ ]]; then
                selected_backup_index=$((chosen_backup_option - 1))

                if [ "$selected_backup_index" -ge 0 ] && [ "$selected_backup_index" -lt "${#backup_list[@]}" ]; then
                    chosen_backup_file=$(basename "${backup_list[selected_backup_index]}")
                    echo ""
                    isNotice "You selected: $chosen_backup_file"
                    restoreStart $saved_selected_app "$chosen_backup_file" "${remote_directory}/${restore_install_name}/$backup_type"
                    return  # Exit the loop once a valid selection is made
                else
                    echo ""
                    isNotice "Invalid backup file selection."
                fi
            else
                echo ""
                isNotice "Invalid input. Please select a valid option or 'b' to go back."
            fi
        done
    }

    select_app
}

restoreCopyFile()
{
    local remote_path="$1"
    local remote_path_save=$remote_path
    if [[ "$restorefull" == [lL] ]] || [[ "$restoresingle" == [lL] ]]; then
        # Extract the date from the filename using sed (assuming the date format is YYYY-MM-DD)
        RestoreBackupDate=$(echo "$chosen_backup_file" | sed -E 's/.*-([0-9]{4}-[0-9]{2}-[0-9]{2})\.zip/\1/')
        isNotice "The Backup file is $chosen_backup_file, using this for restore."
        result=$(copyFile "$BACKUP_SAVE_DIRECTORY/$chosen_backup_file" "$RESTORE_SAVE_DIRECTORY")
        checkSuccess "Copying over $chosen_backup_file to the local Restore Directory"
    elif [[ "$restorefull" == [rR] ]] || [[ "$restoresingle" == [rR] ]]; then
        # Extract the date from the filename (assuming the date format is YYYY-MM-DD)
        RestoreBackupDate=$(echo "$chosen_backup_file" | cut -d'-' -f1-3)
        isNotice "The Backup file is $chosen_backup_file, using this for restore."
        if [[ "$remote_server" == "1" ]]; then
            result=$(sudo -u $easydockeruser sshpass -p "$CFG_BACKUP_REMOTE_1_PASS" scp -o StrictHostKeyChecking=no "$CFG_BACKUP_REMOTE_1_USER"@"$CFG_BACKUP_REMOTE_1_IP":"$remote_path_save/$chosen_backup_file" "$RESTORE_SAVE_DIRECTORY")
            checkSuccess "Copy $chosen_backup_file from $CFG_BACKUP_REMOTE_1_IP to $RESTORE_SAVE_DIRECTORY"
        elif [[ "$remote_server" == "2" ]]; then
            result=$(sudo -u $easydockeruser sshpass -p "$CFG_BACKUP_REMOTE_2_PASS" scp -o StrictHostKeyChecking=no "$CFG_BACKUP_REMOTE_2_USER"@"$CFG_BACKUP_REMOTE_2_IP":"$remote_path_save/$chosen_backup_file" "$RESTORE_SAVE_DIRECTORY")
            checkSuccess "Copy $chosen_backup_file from $CFG_BACKUP_REMOTE_2_IP to $RESTORE_SAVE_DIRECTORY"
        fi
    elif [[ "$restorefull" == [mM] ]] || [[ "$restoresingle" == [mM] ]]; then
        # Extract the date from the filename using sed (assuming the date format is YYYY-MM-DD)
        RestoreBackupDate=$(echo "$chosen_backup_file" | sed -E 's/.*-([0-9]{4}-[0-9]{2}-[0-9]{2})\.zip/\1/')
        isNotice "The Backup file is $chosen_backup_file, using this for restore."
        result=$(copyFile "$BACKUP_SAVE_DIRECTORY/$chosen_backup_file" "$RESTORE_SAVE_DIRECTORY")
        checkSuccess "Copying over $chosen_backup_file to the local Restore Directory"
    fi
}

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
        # Run rsync command to delete everything in base_dir except the specified folders
        result=$(sudo rsync -a --delete $exclude_options "$base_dir/" "$base_dir")
        checkSuccess "Deleting the $app_name Docker install folder $base_dir"
    elif [[ "$restoresingle" == [lLrRmM] ]]; then
        result=$(sudo rm -rf $install_dir$app_name)
        checkSuccess "Deleting the $app_name Docker install folder in $install_dir$app_name"
    fi
}

restoreExtractFile()
{
    cd $RESTORE_SAVE_DIRECTORY
    # Function to attempt decryption with a passphrase
    attempt_decryption() 
    {
        local passphrase="$1"
        local unzip_path="$2"
        isNotice "Attempting to decrypt and unzip $chosen_backup_file backup file...this may take a while..."
        result=$(sudo unzip -o -P "$passphrase" "$chosen_backup_file" -d $unzip_path)
        return $?
    }

    # Local Full
    if [[ "$restorefull" == [lL] ]]; then
        while true; do
            if [ -n "$CFG_BACKUP_PASSPHRASE" ]; then
                # Attempt to decrypt using CFG_BACKUP_PASSPHRASE
                attempt_decryption "$CFG_BACKUP_PASSPHRASE" "/"
        
                if [ $? -eq 0 ]; then
                    checkSuccess "Decrypting $chosen_backup_file (Local) with Backup Passphrase"
                    break
                else
                    isNotice "Decryption failed with the provided passphrase."
                    echo ""
                fi
            fi

            if [ -n "$CFG_RESTORE_REMOTE_BACKUP_PASSPHRASE" ]; then
                # Attempt to decrypt using CFG_RESTORE_REMOTE_BACKUP_PASSPHRASE
                attempt_decryption "$CFG_RESTORE_REMOTE_BACKUP_PASSPHRASE" "/"
        
                if [ $? -eq 0 ]; then
                    checkSuccess "Decrypting $chosen_backup_file (Remote) with Restore Remote Backup Passphrase"
                    break
                else
                    isNotice "Decryption failed with the remote passphrase."
                    echo ""
                fi
            fi

            # Prompt the user for a passphrase
            isQuestion "Enter the passphrase for $chosen_backup_file or 'x' to exit: "
            read -s -r passphrase

            if [ "$passphrase" = "x" ]; then
                isNotice "Exiting..."
                exit 1
            fi

            # Attempt to decrypt using the user-provided passphrase
            attempt_decryption "$passphrase" "/"
            
            if [ $? -eq 0 ]; then
                checkSuccess "Decrypting $chosen_backup_file with the provided passphrase"
                break
            else
                isNotice "Decryption failed with the provided passphrase."
                echo ""
            fi
        done
    fi

    # Remote Full
    if [[ "$restorefull" == [rR] ]]; then
        while true; do
            if [ -n "$CFG_BACKUP_PASSPHRASE" ]; then
                # Attempt to decrypt using CFG_BACKUP_PASSPHRASE
                attempt_decryption "$CFG_BACKUP_PASSPHRASE" "/"
        
                if [ $? -eq 0 ]; then
                    checkSuccess "Decrypting $chosen_backup_file (Remote) with Backup Passphrase"
                    break
                else
                    isNotice "Decryption failed with the provided passphrase."
                    echo ""
                fi
            fi

            if [ -n "$CFG_RESTORE_REMOTE_BACKUP_PASSPHRASE" ]; then
                # Attempt to decrypt using CFG_RESTORE_REMOTE_BACKUP_PASSPHRASE
                attempt_decryption "$CFG_RESTORE_REMOTE_BACKUP_PASSPHRASE" "/"
        
                if [ $? -eq 0 ]; then
                    checkSuccess "Decrypting $chosen_backup_file (Remote) with Restore Remote Backup Passphrase"
                    break
                else
                    isNotice "Decryption failed with the remote passphrase."
                    echo ""
                fi
            fi

            # Prompt the user for a passphrase
            isQuestion "Enter the passphrase for $chosen_backup_file or 'x' to exit: "
            read -s -r passphrase

            if [ "$passphrase" = "x" ]; then
                isNotice "Exiting..."
                exit 1
            fi

            # Attempt to decrypt using the user-provided passphrase
            attempt_decryption "$passphrase" "/"
            
            if [ $? -eq 0 ]; then
                checkSuccess "Decrypting $chosen_backup_file with the provided passphrase"
                break
            else
                isNotice "Decryption failed with the provided passphrase."
                echo ""
            fi
        done
    fi

    # Remote Migrate
    if [[ "$restorefull" == [mM] ]]; then
        while true; do
            result=$(sudo unzip -o -P $CFG_RESTORE_REMOTE_BACKUP_PASSPHRASE $chosen_backup_file -d /)

            if [ $? -eq 0 ]; then
                checkSuccess "Decrypting $chosen_backup_file (Remote Migration)"
                break
            else
                isNotice "Decryption failed with the provided passphrase."
                echo ""
                isQuestion "Enter the passphrase for $chosen_backup_file or 'x' to exit: "
                read -s -r passphrase

                if [ "$passphrase" = "x" ]; then
                    isNotice "Exiting..."
                    exit 1
                fi
            fi
        done
    fi

    # Local Restore
    if [[ "$restoresingle" == [lL] ]]; then
        while true; do
            if [ -n "$CFG_BACKUP_PASSPHRASE" ]; then
                # Attempt to decrypt using CFG_BACKUP_PASSPHRASE
                attempt_decryption "$CFG_BACKUP_PASSPHRASE" "$install_dir"

                if [ $? -eq 0 ]; then
                    checkSuccess "Decrypting $chosen_backup_file (Local) with Backup Passphrase"
                    break
                else
                    isNotice "Decryption failed with the provided passphrase."
                fi
            fi

            if [ -n "$CFG_RESTORE_REMOTE_BACKUP_PASSPHRASE" ]; then
                # Attempt to decrypt using CFG_RESTORE_REMOTE_BACKUP_PASSPHRASE
                attempt_decryption "$CFG_RESTORE_REMOTE_BACKUP_PASSPHRASE" "$install_dir"

                if [ $? -eq 0 ]; then
                    checkSuccess "Decrypting $chosen_backup_file (Remote) with Restore Remote Backup Passphrase"
                    break
                else
                    isNotice "Decryption failed with the remote passphrase."
                fi
            fi

            # Prompt the user for a passphrase
            isQuestion "Enter the passphrase for $chosen_backup_file or 'x' to exit: "
            read -s -r passphrase

            if [ "$passphrase" = "x" ]; then
                isNotice "Exiting..."
                exit 1
            fi

            # Attempt to decrypt using the user-provided passphrase
            attempt_decryption "$passphrase" "$install_dir"

            if [ $? -eq 0 ]; then
                checkSuccess "Decrypting $chosen_backup_file with the provided passphrase"
                break
            else
                isNotice "Decryption failed with the provided passphrase."
            fi
        done
    fi


    # Remote Restore
    if [[ "$restoresingle" == [rR] ]]; then
        while true; do
            if [ -n "$CFG_BACKUP_PASSPHRASE" ]; then
                # Attempt to decrypt using CFG_BACKUP_PASSPHRASE
                attempt_decryption "$CFG_BACKUP_PASSPHRASE" "$install_dir"

                if [ $? -eq 0 ]; then
                    checkSuccess "Decrypting $chosen_backup_file (Remote) with Backup Passphrase"
                    break
                else
                    isNotice "Decryption failed with the provided passphrase."
                fi
            fi

            if [ -n "$CFG_RESTORE_REMOTE_BACKUP_PASSPHRASE" ]; then
                # Attempt to decrypt using CFG_RESTORE_REMOTE_BACKUP_PASSPHRASE
                attempt_decryption "$CFG_RESTORE_REMOTE_BACKUP_PASSPHRASE" "$install_dir"

                if [ $? -eq 0 ]; then
                    checkSuccess "Decrypting $chosen_backup_file (Remote) with Restore Remote Backup Passphrase"
                    break
                else
                    isNotice "Decryption failed with the remote passphrase."
                fi
            fi

            # Prompt the user for a passphrase
            isQuestion "Enter the passphrase for $chosen_backup_file or 'x' to exit: "
            read -s -r passphrase

            if [ "$passphrase" = "x" ]; then
                isNotice "Exiting..."
                exit 1
            fi

            # Attempt to decrypt using the user-provided passphrase
            attempt_decryption "$passphrase" "$install_dir"

            if [ $? -eq 0 ]; then
                checkSuccess "Decrypting $chosen_backup_file with the provided passphrase"
                break
            else
                isNotice "Decryption failed with the provided passphrase."
            fi
        done
    fi


    # Remote Migrate
    if [[ "$restoresingle" == [mM] ]]; then
        while true; do
            result=$(sudo unzip -o -P $CFG_RESTORE_REMOTE_BACKUP_PASSPHRASE $chosen_backup_file -d $install_dir)

            if [ $? -eq 0 ]; then
                checkSuccess "Decrypting $chosen_backup_file (Remote Migration)"
                break
            else
                isNotice "Decryption failed with the provided passphrase."
                echo ""
                isQuestion "Enter the passphrase for $chosen_backup_file or 'x' to exit: "
                read -s -r passphrase

                if [ "$passphrase" = "x" ]; then
                    isNotice "Exiting..."
                    exit 1
                fi
            fi
        done
    fi
}

restoreCleanFiles()
{
    if [[ "$restorefull" == [lLrRmM] ]]; then
        result=$(sudo rm -rf $RESTORE_SAVE_DIRECTORY/*.zip)
        checkSuccess "Clearing unneeded restore data"
    elif [[ "$restoresingle" == [lLrRmM] ]]; then
        result=$(sudo rm -rf $RESTORE_SAVE_DIRECTORY/*.zip)
        checkSuccess "Clearing unneeded restore data"
    fi
}

restoreMigrate()
{
    if [[ "$restorefull" == [lLrRmM] ]]; then
        local app_name="full"
        local chosen_backup_file="$2"
        # Delete everything after the .zip extension in the file name
        local file_name=$(echo "$chosen_backup_file" | sed 's/\(.*\)\.zip/\1.zip/')
        BACKUP_SAVE_DIRECTORY="$backup_full_dir"
        RESTORE_SAVE_DIRECTORY="$restore_full_dir"
        restoreStart "$app_name" "$file_name";
    elif [[ "$restoresingle" == [lLrRmM] ]]; then
        local app_name="$1"
        local chosen_backup_file="$2"
        # Delete everything after the .zip extension in the file name
        local file_name=$(echo "$chosen_backup_file" | sed 's/\(.*\)\.zip/\1.zip/')
        BACKUP_SAVE_DIRECTORY="$backup_single_dir"
        RESTORE_SAVE_DIRECTORY="$restore_single_dir"
        restoreStart "$app_name" "$file_name";
    fi
}

restoreInitialize()
{
    if [[ "$restorefull" == [lLrRmM] ]]; then
        if [[ "$CFG_REQUIREMENT_MIGRATE" == "false" ]]; then
            migrateEnableConfig;
            BACKUP_SAVE_DIRECTORY="$backup_full_dir"
            RESTORE_SAVE_DIRECTORY="$restore_full_dir"
            restoreFullBackupList;
        elif [[ "$CFG_REQUIREMENT_MIGRATE" == "true" ]]; then
            BACKUP_SAVE_DIRECTORY="$backup_full_dir"
            RESTORE_SAVE_DIRECTORY="$restore_full_dir"
            restoreFullBackupList;
        fi
    elif [[ "$restoresingle" == [lLrRmM] ]]; then
        if [[ "$CFG_REQUIREMENT_MIGRATE" == "false" ]]; then
            migrateEnableConfig;
            BACKUP_SAVE_DIRECTORY="$backup_single_dir"
            RESTORE_SAVE_DIRECTORY="$restore_single_dir"
            restoreSingleBackupList;
        elif [[ "$CFG_REQUIREMENT_MIGRATE" == "true" ]]; then
            BACKUP_SAVE_DIRECTORY="$backup_single_dir"
            RESTORE_SAVE_DIRECTORY="$restore_single_dir"
            restoreSingleBackupList;
        fi
    fi
}