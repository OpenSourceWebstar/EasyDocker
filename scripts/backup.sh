#!/bin/bash

backupStart()
{
    local app_name="$1"
    local backup_file_name="$2"
    local backup_save_directory="$3"
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

    backupExistsCheck $app_name $backup_file_name $backup_save_directory;

	((menu_number++))
    echo ""
    echo "---- $menu_number. Shutting container(s) for backup"
    echo ""

    if [ "$stored_app_name" == "full" ]; then
        dockerStopAllApps;
    else
        dockerAppDown $stored_app_name;
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
        dockerAppUp $stored_app_name;
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
    local app_name="$1"
    local backup_file_name="$2"
    local backup_save_directory="$3"

    # Safeguarding
    if [ "$app_name" == "" ]; then
        isNotice "Empty app_name, something went wrong"
        exit
    fi

    if [ "$app_name" == "full" ]; then
        if [ -f "$backup_save_directory/$backup_file_name.zip" ]; then
            while true; do
                isQuestion "Full Backup file already exists. Would you like to overwrite it? (y/n): "
                read -r "" backupfullfileexists
                if [[ -n "$backupfullfileexists" ]]; then
                    break
                fi
                isNotice "Please provide a valid input."
            done
        else
            isSuccessful "No backup files found to replace."
        fi
    elif [ "$app_name" != "full" ]; then
        if [ -f "$backup_save_directory/$backup_file_name.zip" ]; then
            while true; do
                isQuestion "Backup file already exists for $app_name. Would you like to overwrite it? (y/n): "
                read -r "" backupsinglefileexists
                if [[ -n "$backupsinglefileexists" ]]; then
                    break
                fi
                isNotice "Please provide a valid input."
            done
        else
            isSuccessful "No backup files found to replace."
        fi
    fi
}

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
    local result=$(mkdirFolders "loud" $sudo_user_name $backup_save_directory)
    checkSuccess "Creating Backup folder in case it doesn't exist"
    isNotice "Starting Compression, this may take a while"
    if [ "$app_name" == "full" ]; then
        # Create a temporary directory
        local temp_dir=$(mktemp -d)

        local result=$(mkdirFolders "loud" $sudo_user_name "$temp_dir/$(basename "$docker_dir")")
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

backupCleanFiles()
{
    # Safeguarding
    if [ "$app_name" == "" ]; then
        isNotice "Empty app_name, something went wrong"
        exit
    fi

    if [ "$app_name" == "full" ]; then
        local result=$(sudo find "$backup_save_directory" -type f -mtime +"$CFG_BACKUP_KEEPDAYS" -delete)
        checkSuccess "Deleting Backups older than $CFG_BACKUP_KEEPDAYS days"
    elif  [ "$app_name" != "full" ]; then
        local result=$(sudo find "$backup_save_directory" -type f -mtime +"$CFG_BACKUP_KEEPDAYS" -delete)
        checkSuccess "Deleting Backups older than $CFG_BACKUP_KEEPDAYS days"
    fi

    if [ "$CFG_BACKUP_REMOTE_1_ENABLED" == "true" ]; then
        if [ "$CFG_BACKUP_REMOTE_1_BACKUP_CLEAN" == "true" ]; then
            if [ "$app_name" == "full" ]; then
                local backup_folder="full"
                local backup_location="$CFG_BACKUP_REMOTE_1_BACKUP_DIRECTORY/$CFG_INSTALL_NAME/$backup_folder"
                local backup_location_clean="$(echo "$backup_location" | sed 's/\/\//\//g')"
                local date_format="20[0-9][0-9]-[0-1][0-9]-[0-3][0-9]"

                isNotice "Cleaning of old files now starting for $CFG_BACKUP_REMOTE_1_IP"

                # List all files in the backup location
                local result=$(sshRemote "$CFG_BACKUP_REMOTE_1_PASS" $CFG_BACKUP_REMOTE_1_PORT "$CFG_BACKUP_REMOTE_1_USER@$CFG_BACKUP_REMOTE_1_IP" "ls $backup_location_clean")

                # Loop through the list of files
                while read -r file_name; do
                    # Extract the date portion from the filename using regex
                    if [[ $file_name =~ ($date_format) ]]; then
                        local file_date="${BASH_REMATCH[1]}"
                        # Calculate the age of the file in days
                        local file_age_in_days=$(( ( $(date +%s) - $(date -d "$file_date" +%s) ) / 86400 ))
                        # Check if the file is older than the specified threshold
                        if [ "$file_age_in_days" -gt "$CFG_BACKUP_REMOTE_1_BACKUP_KEEPDAYS" ]; then
                            # Remove the file
                            local result=$(sshRemote "$CFG_BACKUP_REMOTE_1_PASS" $CFG_BACKUP_REMOTE_1_PORT "$CFG_BACKUP_REMOTE_1_USER@$CFG_BACKUP_REMOTE_1_IP" "rm $backup_location_clean/$file_name")
                            isSuccessful "Removed file: $file_name"
                        fi
                    fi
                done <<< "$result"

                isSuccessful "Removed all files older than $CFG_BACKUP_REMOTE_1_BACKUP_KEEPDAYS days"

            elif [ "$app_name" != "full" ]; then
                local backup_folder="single"
                local backup_location="$CFG_BACKUP_REMOTE_1_BACKUP_DIRECTORY/$CFG_INSTALL_NAME/$backup_folder"
                local backup_location_clean="$(echo "$backup_location" | sed 's/\/\//\//g')"
                local date_format="20[0-9][0-9]-[0-1][0-9]-[0-3][0-9]"
                
                isNotice "Cleaning of old files now starting for $CFG_BACKUP_REMOTE_1_IP"

                # List all files in the backup location
                local result=$(sshRemote "$CFG_BACKUP_REMOTE_1_PASS" $CFG_BACKUP_REMOTE_1_PORT "$CFG_BACKUP_REMOTE_1_USER@$CFG_BACKUP_REMOTE_1_IP" "ls $backup_location_clean")

                # Loop through the list of files
                while read -r file_name; do
                    # Extract the date portion from the filename using regex
                    if [[ $file_name =~ ($date_format) ]]; then
                        local file_date="${BASH_REMATCH[1]}"
                        # Calculate the age of the file in days
                        local file_age_in_days=$(( ( $(date +%s) - $(date -d "$file_date" +%s) ) / 86400 ))
                        # Check if the file is older than the specified threshold
                        if [ "$file_age_in_days" -gt "$CFG_BACKUP_REMOTE_1_BACKUP_KEEPDAYS" ]; then
                            # Remove the file
                            local result=$(sshRemote "$CFG_BACKUP_REMOTE_1_PASS" $CFG_BACKUP_REMOTE_1_PORT "$CFG_BACKUP_REMOTE_1_USER@$CFG_BACKUP_REMOTE_1_IP" "rm $backup_location_clean/$file_name")
                            isSuccessful "Removed file: $file_name"
                        fi
                    fi
                done <<< "$result"

                isSuccessful "Removed all files older than $CFG_BACKUP_REMOTE_1_BACKUP_KEEPDAYS days"
            fi
        fi
    fi

    if [ "$CFG_BACKUP_REMOTE_2_ENABLED" == "true" ]; then
        if [ "$CFG_BACKUP_REMOTE_2_BACKUP_CLEAN" == "true" ]; then
            if [ "$app_name" == "full" ]; then
                local backup_folder="full"
                local backup_location="$CFG_BACKUP_REMOTE_2_BACKUP_DIRECTORY/$CFG_INSTALL_NAME/$backup_folder"
                local backup_location_clean="$(echo "$backup_location" | sed 's/\/\//\//g')"
                local date_format="20[0-9][0-9]-[0-1][0-9]-[0-3][0-9]"
                
                isNotice "Cleaning of old files now starting for $CFG_BACKUP_REMOTE_2_IP"

                # List all files in the backup location
                local result=$(sshRemote "$CFG_BACKUP_REMOTE_2_PASS" $CFG_BACKUP_REMOTE_2_PORT "$CFG_BACKUP_REMOTE_2_USER@$CFG_BACKUP_REMOTE_2_IP" "ls $backup_location_clean")

                # Loop through the list of files
                while read -r file_name; do
                    # Extract the date portion from the filename using regex
                    if [[ $file_name =~ ($date_format) ]]; then
                        local file_date="${BASH_REMATCH[1]}"
                        # Calculate the age of the file in days
                        local file_age_in_days=$(( ( $(date +%s) - $(date -d "$file_date" +%s) ) / 86400 ))
                        # Check if the file is older than the specified threshold
                        if [ "$file_age_in_days" -gt "$CFG_BACKUP_REMOTE_2_BACKUP_KEEPDAYS" ]; then
                            # Remove the file
                            local result=$(sshRemote "$CFG_BACKUP_REMOTE_2_PASS" $CFG_BACKUP_REMOTE_2_PORT "$CFG_BACKUP_REMOTE_2_USER@$CFG_BACKUP_REMOTE_2_IP" "rm $backup_location_clean/$file_name")
                            isSuccessful "Removed file: $file_name"
                        fi
                    fi
                done <<< "$result"

                isSuccessful "Removed all files older than $CFG_BACKUP_REMOTE_2_BACKUP_KEEPDAYS days"
            elif [ "$app_name" != "full" ]; then
                local backup_folder="single"
                local backup_location="$CFG_BACKUP_REMOTE_2_BACKUP_DIRECTORY/$CFG_INSTALL_NAME/$backup_folder"
                local backup_location_clean="$(echo "$backup_location" | sed 's/\/\//\//g')"
                local date_format="20[0-9][0-9]-[0-1][0-9]-[0-3][0-9]"
                
                isNotice "Cleaning of old files now starting for $CFG_BACKUP_REMOTE_2_IP"

                # List all files in the backup location
                local result=$(sshRemote "$CFG_BACKUP_REMOTE_2_PASS" $CFG_BACKUP_REMOTE_2_PORT "$CFG_BACKUP_REMOTE_2_USER@$CFG_BACKUP_REMOTE_2_IP" "ls $backup_location_clean")

                # Loop through the list of files
                while read -r file_name; do
                    # Extract the date portion from the filename using regex
                    if [[ $file_name =~ ($date_format) ]]; then
                        file_date="${BASH_REMATCH[1]}"
                        # Calculate the age of the file in days
                        file_age_in_days=$(( ( $(date +%s) - $(date -d "$file_date" +%s) ) / 86400 ))
                        # Check if the file is older than the specified threshold
                        if [ "$file_age_in_days" -gt "$CFG_BACKUP_REMOTE_2_BACKUP_KEEPDAYS" ]; then
                            # Remove the file
                            local result=$(sshRemote "$CFG_BACKUP_REMOTE_2_PASS" $CFG_BACKUP_REMOTE_2_PORT "$CFG_BACKUP_REMOTE_2_USER@$CFG_BACKUP_REMOTE_2_IP" "rm $backup_location_clean/$file_name")
                            isSuccessful "Removed file: $file_name"
                        fi
                    fi
                done <<< "$result"

                isSuccessful "Removed all files older than $CFG_BACKUP_REMOTE_2_BACKUP_KEEPDAYS days"
            fi
        fi
    fi
}

backupFindLatestFile()
{
    local app_name="$1"

    # Safeguarding
    if [ "$app_name" == "" ]; then
        isNotice "Empty app_name, something went wrong"
        exit
    fi

    if [ "$app_name" == "full" ]; then
        cd $backup_save_directory
        local latest_backup_file=$(sudo -u $sudo_user_name ls -t *"$backupDate.zip" | head -n 1)
        isNotice "Latest backup found file: $latest_backup_file"
        if [ -z "$latest_backup_file" ]; then
            isNotice "No backup files found for $app_name on $backupDate."
        else
            backupTransferFile $app_name $latest_backup_file;
        fi
    elif [ "$app_name" != "full" ]; then
        cd $backup_save_directory
        local latest_backup_file=$(sudo find . -maxdepth 1 -type f -regex ".*${app_name}.*${backupDate}\.zip" | sort -r | head -n 1)
        if [ -z "$latest_backup_file" ]; then
            isNotice "No backup files found for $app_name on $backupDate."
        else
            backupTransferFile $app_name $latest_backup_file;
        fi
    fi
}

backupTransferFile()
{
    local app_name="$1"
    local latest_backup_file="$2"

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
        isNotice "Remote backup enabled, transfering file : $latest_backup_file"
        if [ "$CFG_BACKUP_REMOTE_1_TYPE" == "SSH" ]; then
            if ssh -o ConnectTimeout=10 "$CFG_BACKUP_REMOTE_1_USER"@"$CFG_BACKUP_REMOTE_1_IP" true; then
                checkSuccess "SSH connection to $CFG_BACKUP_REMOTE_1_IP is established."
                local result=$(sudo -u $sudo_user_name scp -o StrictHostKeyChecking=no UserKnownHostsFile=/dev/null "$latest_backup_file" "$CFG_BACKUP_REMOTE_1_USER"@"$CFG_BACKUP_REMOTE_1_IP":"$backup_location_clean")
                checkSuccess "Transfering $app_name backup to Remote Backup Host - $CFG_BACKUP_REMOTE_1_IP"
            else
                checkSuccess "Unable to connect to SSH for $CFG_BACKUP_REMOTE_1_IP"
            fi
        elif [ "$CFG_BACKUP_REMOTE_1_TYPE" == "LOGIN" ]; then
            if sshRemote "$CFG_BACKUP_REMOTE_1_PASS" $CFG_BACKUP_REMOTE_1_PORT "$CFG_BACKUP_REMOTE_1_USER@$CFG_BACKUP_REMOTE_1_IP" "mkdir -p \"$backup_location_clean\""; then
                isSuccessful "Creating remote folders"
                isNotice "Transfer of $app_name to $CFG_BACKUP_REMOTE_1_IP. Please wait... it may take a while..."
                if sudo -u $sudo_user_name sshpass -p "$CFG_BACKUP_REMOTE_1_PASS" scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$latest_backup_file" "$CFG_BACKUP_REMOTE_1_USER@$CFG_BACKUP_REMOTE_1_IP:$backup_location_clean"; then
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
        isNotice "Remote backup enabled, transfering file : $latest_backup_file"
        if [ "$CFG_BACKUP_REMOTE_2_TYPE" == "SSH" ]; then
            if ssh -o ConnectTimeout=10 "$CFG_BACKUP_REMOTE_2_USER"@"$CFG_BACKUP_REMOTE_2_IP" true; then
                checkSuccess "SSH connection to $CFG_BACKUP_REMOTE_2_IP is established."
                local result=$(sudo -u $sudo_user_name scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$latest_backup_file" "$CFG_BACKUP_REMOTE_2_USER"@"$CFG_BACKUP_REMOTE_2_IP":"$backup_location_clean")
                checkSuccess "Transfering $app_name backup to Remote Backup Host - $CFG_BACKUP_REMOTE_2_IP"
            else
                checkSuccess "Unable to connect to SSH for $CFG_BACKUP_REMOTE_2_IP"
            fi
        elif [ "$CFG_BACKUP_REMOTE_2_TYPE" == "LOGIN" ]; then
            if sshRemote "$CFG_BACKUP_REMOTE_2_PASS" $CFG_BACKUP_REMOTE_2_PORT "$CFG_BACKUP_REMOTE_2_USER@$CFG_BACKUP_REMOTE_2_IP" "mkdir -p \"$backup_location_clean\""; then
                isSuccessful "Creating remote folders"
                isNotice "Transfer of $app_name to $CFG_BACKUP_REMOTE_2_IP. Please wait... it may take a while..."
                if sudo -u $sudo_user_name sshpass -p "$CFG_BACKUP_REMOTE_2_PASS" scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$latest_backup_file" "$CFG_BACKUP_REMOTE_2_USER@$CFG_BACKUP_REMOTE_2_IP:$backup_location_clean"; then
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
    local app_name=$1
    
    # Safeguarding
    if [ "$app_name" == "" ]; then
        isNotice "Empty app_name, something went wrong"
        exit
    fi

    local backup_file_name="$CFG_INSTALL_NAME-$app_name-backup-$backupDate"
    if [ "$app_name" == "full" ]; then
        local backup_save_directory="$backup_full_dir"
    elif [ "$app_name" != "full" ]; then
        local backup_save_directory="$backup_single_dir"
    fi
    backupStart $app_name $backup_file_name $backup_save_directory;
}   