#!/bin/bash

app_name="$1"
param2="$2"

backupStart()
{
    local stored_app_name=$app_name
    echo ""
    echo "##########################################"
    echo "###      Backing up $stored_app_name"
    echo "##########################################"
    echo ""

	((menu_number++))
    echo ""
    echo "---- $menu_number. Checking exisiting backup files"
    echo ""

    backupExistsCheck;

	((menu_number++))
    echo ""
    echo "---- $menu_number. Shutting container(s) for backup"
    echo ""

    if [ "$stored_app_name" == "full" ]; then
        dockerStopAllApps;
    else
        dockerAppDown;
    fi

	((menu_number++))
    echo ""
    echo "---- $menu_number. Backing up $stored_app_name docker folder"
    echo ""

    backupZipFile;

	((menu_number++))
    echo ""
    echo "---- $menu_number. Starting up all docker containers"
    echo ""

    if [ "$stored_app_name" == "full" ]; then
        dockerStartAllApps;
    else
        dockerAppUp $stored_app_name;
    fi

    if [ "$CFG_BACKUP_REMOTE_1_ENABLED" == "true" ] || [ "$CFG_BACKUP_REMOTE_1_ENABLED" == "true" ]; then

	    ((menu_number++))
        echo ""
        echo "---- $menu_number. Transfering backup file to remote server(s)"
        echo ""

        backupFindLatestFile;
    fi

	((menu_number++))
    echo ""
    echo "---- $menu_number. Logging backup into database"
    echo ""

    databaseBackupInsert $stored_app_name;

	((menu_number++))
    echo ""
    echo "---- $menu_number. Cleaning backup files older than $CFG_BACKUP_KEEPDAYS days"
    echo ""

    backupCleanFiles;

	((menu_number++))
    echo ""
    echo "    A backup of the $stored_app_name docker folder has been taken!"
    echo ""

	menu_number=0
    backupsingle=n
    backupfull=n
    cd
}

# Generic Functions
backupExistsCheck()
{
    # Safeguarding
    if [ "$app_name" == "" ]; then
        isNotice "Empty app_name, something went wrong"
        exit
    fi

    if [ "$app_name" == "full" ]; then
        if [ -f "$BACKUP_SAVE_DIRECTORY/$BACKUP_FILE_NAME.zip" ]; then
            while true; do
                isQuestion "Full Backup file already exists. Would you like to overwrite it? (y/n): "
                read -rp "" backupfullfileexists
                if [[ -n "$backupfullfileexists" ]]; then
                    break
                fi
                isNotice "Please provide a valid input."
            done
        fi
    elif [ "$app_name" != "full" ]; then
        if [ -f "$BACKUP_SAVE_DIRECTORY/$BACKUP_FILE_NAME.zip" ]; then
            while true; do
                isQuestion "Backup file already exists for $app_name. Would you like to overwrite it? (y/n): "
                read -rp "" backupsinglefileexists
                if [[ -n "$backupsinglefileexists" ]]; then
                    break
                fi
                isNotice "Please provide a valid input."
            done
        fi
    fi
}

backupZipFile()
{
    # Safeguarding
    if [ "$app_name" == "" ]; then
        isNotice "Empty app_name, something went wrong"
        exit
    fi

    isNotice "The new Backup file will be named : ${BACKUP_FILE_NAME}.zip"
    result=$(mkdirFolders $BACKUP_SAVE_DIRECTORY)
    checkSuccess "Creating Backup folder in case it doesn't exist"
    isNotice "Starting Compression, this may take a while"
    if [ "$app_name" == "full" ]; then
        # Create a temporary directory
        temp_dir=$(mktemp -d)

        result=$(mkdirFolders "$temp_dir/$(basename "$base_dir")")
        checkSuccess "Create the $base_dir inside the temporary directory"

        result=$(cd $base_dir && sudo cp -r --parents database.db containers/ ssl/ install/configs/ "$temp_dir/$(basename "$base_dir")")
        checkSuccess "Copy the data to the temporary directory"

        result=$(cd "$temp_dir" && zipFile "$CFG_BACKUP_PASSPHRASE" "$BACKUP_SAVE_DIRECTORY/$BACKUP_FILE_NAME.zip" "$(basename "$base_dir")")
        checkSuccess "Create the zip command to include duplicates in the zip file"

        result=$(sudo rm -r "$temp_dir")
        checkSuccess "Remove the temporary directory"

        #checkSuccess "Compressing $app_name folder into an encrypted zip file"
    elif [ "$app_name" != "full" ]; then
        result=$(cd $install_path && zipFile "$CFG_BACKUP_PASSPHRASE" "$BACKUP_SAVE_DIRECTORY/$BACKUP_FILE_NAME.zip" "$app_name")
        checkSuccess "Compressing $app_name folder into an encrypted zip file"
    fi
}

backupCleanFiles()
{
    # Safeguarding
    if [ "$app_name" == "" ]; then
        isNotice "Empty app_name, something went wrong"
        exit
    fi

    if [ "$app_name" == "full" ]; then
        result=$(sudo find "$BACKUP_SAVE_DIRECTORY" -type f -mtime +"$CFG_BACKUP_KEEPDAYS" -delete)
        checkSuccess "Deleting Backups older than $CFG_BACKUP_KEEPDAYS days"
    elif  [ "$app_name" != "full" ]; then
        result=$(sudo find "$BACKUP_SAVE_DIRECTORY" -type f -mtime +"$CFG_BACKUP_KEEPDAYS" -delete)
        checkSuccess "Deleting Backups older than $CFG_BACKUP_KEEPDAYS days"
    fi

    local backup_location="$CFG_BACKUP_REMOTE_1_BACKUP_DIRECTORY/$CFG_INSTALL_NAME/$backup_folder"
    local backup_location_clean="$(echo "$backup_location" | sed 's/\/\//\//g')"
    local date_format="20[0-9][0-9]-[0-1][0-9]-[0-3][0-9]"

    if [ "$CFG_BACKUP_REMOTE_1_ENABLED" == "true" ]; then
        if [ "$CFG_BACKUP_REMOTE_1_BACKUP_CLEAN" == "true" ]; then
            if [ "$app_name" == "full" ]; then
                local backup_folder="full"
                # List files in the remote directory
                result=$(sudo -u $easydockeruser sshpass -p "$CFG_BACKUP_REMOTE_1_PASS" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $CFG_BACKUP_REMOTE_1_PORT "$CFG_BACKUP_REMOTE_1_USER@$CFG_BACKUP_REMOTE_1_IP" "ls $backup_directory")
                files_to_remove=$(echo "$result" | grep -E "$date_format")

                while read -r file_to_remove; do
                sudo -u $easydockeruser sshpass -p "$CFG_BACKUP_REMOTE_1_PASS" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $CFG_BACKUP_REMOTE_1_PORT "$CFG_BACKUP_REMOTE_1_USER@$CFG_BACKUP_REMOTE_1_IP" "rm $backup_directory/$file_to_remove"
                echo "Removed file: $file_to_remove"
                done <<< "$files_to_remove"

                isSuccessful "Removed all files older than $CFG_BACKUP_REMOTE_1_BACKUP_KEEPDAYS days"
            elif [ "$app_name" != "full" ]; then
                local backup_folder="single"
                # List files in the remote directory
                result=$(sudo -u $easydockeruser sshpass -p "$CFG_BACKUP_REMOTE_1_PASS" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $CFG_BACKUP_REMOTE_1_PORT "$CFG_BACKUP_REMOTE_1_USER@$CFG_BACKUP_REMOTE_1_IP" "ls $backup_directory")
                files_to_remove=$(echo "$result" | grep -E "$date_format")

                while read -r file_to_remove; do
                sudo -u $easydockeruser sshpass -p "$CFG_BACKUP_REMOTE_1_PASS" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $CFG_BACKUP_REMOTE_1_PORT "$CFG_BACKUP_REMOTE_1_USER@$CFG_BACKUP_REMOTE_1_IP" "rm $backup_directory/$file_to_remove"
                echo "Removed file: $file_to_remove"
                done <<< "$files_to_remove"
                
                isSuccessful "Removed all files older than $CFG_BACKUP_REMOTE_1_BACKUP_KEEPDAYS days"
            fi
        fi
    fi

    if [ "$CFG_BACKUP_REMOTE_2_ENABLED" == "true" ]; then
        if [ "$CFG_BACKUP_REMOTE_2_BACKUP_CLEAN" == "true" ]; then
            if [ "$app_name" == "full" ]; then
                local backup_folder="full"
                # List files in the remote directory
                result=$(sudo -u $easydockeruser sshpass -p "$CFG_BACKUP_REMOTE_2_PASS" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $CFG_BACKUP_REMOTE_2_PORT "$CFG_BACKUP_REMOTE_2_USER@$CFG_BACKUP_REMOTE_2_IP" "ls $backup_directory")
                files_to_remove=$(echo "$result" | grep -E "$date_format")

                while read -r file_to_remove; do
                sudo -u $easydockeruser sshpass -p "$CFG_BACKUP_REMOTE_2_PASS" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $CFG_BACKUP_REMOTE_2_PORT "$CFG_BACKUP_REMOTE_2_USER@$CFG_BACKUP_REMOTE_2_IP" "rm $backup_directory/$file_to_remove"
                echo "Removed file: $file_to_remove"
                done <<< "$files_to_remove"

                isSuccessful "Removed all files older than $CFG_BACKUP_REMOTE_2_BACKUP_KEEPDAYS days"
            elif [ "$app_name" != "full" ]; then
                local backup_folder="single"
                # List files in the remote directory
                result=$(sudo -u $easydockeruser sshpass -p "$CFG_BACKUP_REMOTE_2_PASS" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $CFG_BACKUP_REMOTE_2_PORT "$CFG_BACKUP_REMOTE_2_USER@$CFG_BACKUP_REMOTE_2_IP" "ls $backup_directory")
                files_to_remove=$(echo "$result" | grep -E "$date_format")

                while read -r file_to_remove; do
                sudo -u $easydockeruser sshpass -p "$CFG_BACKUP_REMOTE_2_PASS" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $CFG_BACKUP_REMOTE_2_PORT "$CFG_BACKUP_REMOTE_2_USER@$CFG_BACKUP_REMOTE_2_IP" "rm $backup_directory/$file_to_remove"
                echo "Removed file: $file_to_remove"
                done <<< "$files_to_remove"
                
                isSuccessful "Removed all files older than $CFG_BACKUP_REMOTE_2_BACKUP_KEEPDAYS days"
            fi
        fi
    fi
}

backupFindLatestFile()
{
    # Safeguarding
    if [ "$app_name" == "" ]; then
        isNotice "Empty app_name, something went wrong"
        exit
    fi

    if [ "$app_name" == "full" ]; then
        cd $BACKUP_SAVE_DIRECTORY
        LatestBackupFile=$(sudo -u $easydockeruser ls -t *"$backupDate.zip" | head -n 1)
        isNotice "Latest backup found file: $LatestBackupFile"
        if [ -z "$LatestBackupFile" ]; then
            isNotice "No backup files found for $app_name on $backupDate."
        else
            backupTransferFile;
        fi
    elif [ "$app_name" != "full" ]; then
        cd $BACKUP_SAVE_DIRECTORY
        LatestBackupFile=$(sudo find . -maxdepth 1 -type f -regex ".*${app_name}.*${backupDate}\.zip" | sort -r | head -n 1)
        if [ -z "$LatestBackupFile" ]; then
            isNotice "No backup files found for $app_name on $backupDate."
        else
            backupTransferFile;
        fi
    fi
}

backupTransferFile()
{
    # Safeguarding
    if [ "$app_name" == "" ]; then
        isNotice "Empty app_name, something went wrong"
        exit
    fi

    if [ "$app_name" == "full" ]; then
        local backup_folder="full"
    elif [ "$app_name" != "full" ]; then
        local backup_folder="single"
    fi

    local backup_location="$CFG_BACKUP_REMOTE_1_BACKUP_DIRECTORY/$CFG_INSTALL_NAME/$backup_folder"
    local backup_location_clean="$(echo "$backup_location" | sed 's/\/\//\//g')"

    if [ "$CFG_BACKUP_REMOTE_1_ENABLED" == "true" ]; then
        isNotice "Remote backup enabled, transfering file : $LatestBackupFile"
        if [ "$CFG_BACKUP_REMOTE_1_TYPE" == "SSH" ]; then
            if ssh -o ConnectTimeout=10 "$CFG_BACKUP_REMOTE_1_USER"@"$CFG_BACKUP_REMOTE_1_IP" true; then
                checkSuccess "SSH connection to $CFG_BACKUP_REMOTE_1_IP is established."
                result=$(sudo -u $easydockeruser scp "$LatestBackupFile" "$CFG_BACKUP_REMOTE_1_USER"@"$CFG_BACKUP_REMOTE_1_IP":"$backup_location_clean")
                checkSuccess "Transfering $app_name backup to Remote Backup Host - $CFG_BACKUP_REMOTE_1_IP"
            else
                checkSuccess "Unable to connect to SSH for $CFG_BACKUP_REMOTE_1_IP"
            fi
        elif [ "$CFG_BACKUP_REMOTE_1_TYPE" == "LOGIN" ]; then
            if sudo -u $easydockeruser sshpass -p "$CFG_BACKUP_REMOTE_1_PASS" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $CFG_BACKUP_REMOTE_1_PORT "$CFG_BACKUP_REMOTE_1_USER@$CFG_BACKUP_REMOTE_1_IP" "mkdir -p \"$backup_location_clean\""; then
                isSuccessful "Creating remote folders"
                isNotice "Transfer of $app_name to $CFG_BACKUP_REMOTE_1_IP. Please wait... it may take a while..."
                if sudo -u $easydockeruser sshpass -p "$CFG_BACKUP_REMOTE_1_PASS" scp "$LatestBackupFile" "$CFG_BACKUP_REMOTE_1_USER@$CFG_BACKUP_REMOTE_1_IP:$backup_location_clean"; then
                    isSuccessful "Transferring $app_name backup to Remote Backup Host - $CFG_BACKUP_REMOTE_1_IP"
                else
                    isError "SCP failed to upload file to $backup_location_clean"
                fi
            else
                isError "SSH connection to $CFG_BACKUP_REMOTE_1_IP failed."
            fi
        fi
    fi

    if [ "$CFG_BACKUP_REMOTE_2_ENABLED" == "true" ]; then
        isNotice "Remote backup enabled, transfering file : $LatestBackupFile"
        if [ "$CFG_BACKUP_REMOTE_2_TYPE" == "SSH" ]; then
            if ssh -o ConnectTimeout=10 "$CFG_BACKUP_REMOTE_2_USER"@"$CFG_BACKUP_REMOTE_2_IP" true; then
                checkSuccess "SSH connection to $CFG_BACKUP_REMOTE_2_IP is established."
                result=$(sudo -u $easydockeruser scp "$LatestBackupFile" "$CFG_BACKUP_REMOTE_2_USER"@"$CFG_BACKUP_REMOTE_2_IP":"$backup_location_clean")
                checkSuccess "Transfering $app_name backup to Remote Backup Host - $CFG_BACKUP_REMOTE_2_IP"
            else
                checkSuccess "Unable to connect to SSH for $CFG_BACKUP_REMOTE_2_IP"
            fi
        elif [ "$CFG_BACKUP_REMOTE_2_TYPE" == "LOGIN" ]; then
            if sudo -u $easydockeruser sshpass -p "$CFG_BACKUP_REMOTE_2_PASS" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $CFG_BACKUP_REMOTE_2_PORT "$CFG_BACKUP_REMOTE_2_USER@$CFG_BACKUP_REMOTE_2_IP" "mkdir -p \"$backup_location_clean\""; then
                isSuccessful "Creating remote folders"
                isNotice "Transfer of $app_name to $CFG_BACKUP_REMOTE_2_IP. Please wait... it may take a while..."
                if sudo -u $easydockeruser sshpass -p "$CFG_BACKUP_REMOTE_2_PASS" scp "$LatestBackupFile" "$CFG_BACKUP_REMOTE_2_USER@$CFG_BACKUP_REMOTE_2_IP:$backup_location_clean"; then
                    isSuccessful "Transferring $app_name backup to Remote Backup Host - $CFG_BACKUP_REMOTE_2_IP"
                else
                    isError "SCP failed to upload file to $backup_location_clean"
                fi
            else
                isError "SSH connection to $CFG_BACKUP_REMOTE_2_IP failed."
            fi
        fi
    fi
}

backupInitialize()
{
    app_name=$1
    
    # Safeguarding
    if [ "$app_name" == "" ]; then
        isNotice "Empty app_name, something went wrong"
        exit
    fi

    BACKUP_FILE_NAME="$CFG_INSTALL_NAME-$app_name-backup-$backupDate"
    if [ "$app_name" == "full" ]; then
        BACKUP_SAVE_DIRECTORY="$backup_full_dir"
    elif [ "$app_name" != "full" ]; then
        BACKUP_SAVE_DIRECTORY="$backup_single_dir"
    fi
    backupStart;
}   