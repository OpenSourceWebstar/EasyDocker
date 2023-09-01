#!/bin/bash

app_name="$1"
param2="$2"

backupStart()
{
    echo ""
    echo "##########################################"
    echo "###      Backing up $app_name"
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

    if [ "$app_name" == "full" ]; then
        dockerStopAllApps;
    else
        dockerAppDown;
    fi

	((menu_number++))
    echo ""
    echo "---- $menu_number. Backing up $app_name docker folder"
    echo ""

    backupZipFile;

	((menu_number++))
    echo ""
    echo "---- $menu_number. Starting up all docker containers"
    echo ""

    if [ "$app_name" == "full" ]; then
        dockerStartAllApps;
    else
        dockerAppUp;
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

    databaseBackupInsert $app_name;

	((menu_number++))
    echo ""
    echo "---- $menu_number. Cleaning backup files older than $CFG_BACKUP_KEEPDAYS days"
    echo ""

    backupCleanFiles;

	((menu_number++))
    echo ""
    echo "    A backup of the $app_name docker folder has been taken!"
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
    result=$(mkdir -p $BACKUP_SAVE_DIRECTORY)
    checkSuccess "Creating Backup folder in case it doesn't exist"
    isNotice "Starting Compression, this may take a while"
    if [ "$app_name" == "full" ]; then
        # Create a temporary directory
        temp_dir=$(mktemp -d)

        result=$(mkdir -p "$temp_dir/$(basename "$base_dir")")
        checkSuccess "Create the $base_dir inside the temporary directory"

        result=$(cd "$base_dir" && find . -exec cp -r --parents {} "$temp_dir/$(basename "$base_dir")" \;)
        checkSuccess "Copy the contents of $base_dir to the temporary directory"

        result=$(cd "$temp_dir" && zip -r -MM -e -P "$CFG_BACKUP_PASSPHRASE" "$BACKUP_SAVE_DIRECTORY/$BACKUP_FILE_NAME.zip" "$(basename "$base_dir")")
        checkSuccess "Create the zip command to include duplicates in the zip file"

        result=$(rm -r "$temp_dir")
        checkSuccess "Remove the temporary directory"

        #checkSuccess "Compressing $app_name folder into an encrypted zip file"
    elif [ "$app_name" != "full" ]; then
        result=$(cd $install_path && zip -r -e -P "$CFG_BACKUP_PASSPHRASE" "$BACKUP_SAVE_DIRECTORY/$BACKUP_FILE_NAME.zip" "$app_name")
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
        result=$(find "$BACKUP_SAVE_DIRECTORY" -type f -mtime +"$CFG_BACKUP_KEEPDAYS" -delete)
        checkSuccess "Deleting Backups older than $CFG_BACKUP_KEEPDAYS days"
    elif  [ "$app_name" != "full" ]; then
        result=$(find "$BACKUP_SAVE_DIRECTORY" -type f -mtime +"$CFG_BACKUP_KEEPDAYS" -delete)
        checkSuccess "Deleting Backups older than $CFG_BACKUP_KEEPDAYS days"
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
        LatestBackupFile=$(ls -t *"$backupDate.zip" | head -n 1)
        isNotice "Latest backup found file: $LatestBackupFile"
        if [ -z "$LatestBackupFile" ]; then
            isNotice "No backup files found for $app_name on $backupDate."
        else
            backupTransferFile;
        fi
    elif [ "$app_name" != "full" ]; then
        cd $BACKUP_SAVE_DIRECTORY
        LatestBackupFile=$(find . -maxdepth 1 -type f -regex ".*${app_name}.*${backupDate}\.zip" | sort -r | head -n 1)
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

    if [ "$CFG_BACKUP_REMOTE_1_ENABLED" == "true" ]; then
        isNotice "Remote backup enabled, transfering file : $LatestBackupFile"
        if [ "$CFG_BACKUP_REMOTE_1_TYPE" == "SSH" ]; then
            if ssh -o ConnectTimeout=10 "$CFG_BACKUP_REMOTE_1_USER"@"$CFG_BACKUP_REMOTE_1_IP" true; then
                checkSuccess "Testing SSH connection to $CFG_BACKUP_REMOTE_1_IP"
                if [ "$app_name" == "full" ]; then
                    result=$(scp "$LatestBackupFile" "$CFG_BACKUP_REMOTE_1_USER"@"$CFG_BACKUP_REMOTE_1_IP":"$CFG_BACKUP_REMOTE_1_BACKUP_DIRECTORY/full")
                    checkSuccess "Transfering $app_name backup to Remote Backup Host - $CFG_BACKUP_REMOTE_1_IP"
                elif [ "$app_name" != "full" ]; then
                    result=$(scp "$LatestBackupFile" "$CFG_BACKUP_REMOTE_1_USER"@"$CFG_BACKUP_REMOTE_1_IP":"$CFG_BACKUP_REMOTE_1_BACKUP_DIRECTORY/single")
                    checkSuccess "Transfering $app_name backup to Remote Backup Host - $CFG_BACKUP_REMOTE_1_IP"
                fi
            else
                checkSuccess "Testing SSH connection to $CFG_BACKUP_REMOTE_1_IP"
            fi
        else
            if [ "$app_name" == "full" ]; then
                result=$(sshpass -p "$CFG_BACKUP_REMOTE_1_PASS" scp "$LatestBackupFile" "$CFG_BACKUP_REMOTE_1_USER"@"$CFG_BACKUP_REMOTE_1_IP":"$CFG_BACKUP_REMOTE_1_BACKUP_DIRECTORY/full")
                checkSuccess "Transferring $app_name backup to Remote Backup Host - $CFG_BACKUP_REMOTE_1_IP"
            elif [ "$app_name" != "full" ]; then
                result=$(sshpass -p "$CFG_BACKUP_REMOTE_1_PASS" scp "$LatestBackupFile" "$CFG_BACKUP_REMOTE_1_USER"@"$CFG_BACKUP_REMOTE_1_IP":"$CFG_BACKUP_REMOTE_1_BACKUP_DIRECTORY/single")
                checkSuccess "Transferring $app_name backup to Remote Backup Host - $CFG_BACKUP_REMOTE_1_IP"
            fi
        fi
    fi


    if [ "$CFG_BACKUP_REMOTE_2_ENABLED" == "true" ]; then
        isNotice "Remote backup enabled, transfering file : $LatestBackupFile"
        if [ "$CFG_BACKUP_REMOTE_2_TYPE" == "SSH" ]; then
            if ssh -o ConnectTimeout=10 "$CFG_BACKUP_REMOTE_2_USER"@"$CFG_BACKUP_REMOTE_2_IP" true; then
                checkSuccess "Testing SSH connection to $CFG_BACKUP_REMOTE_2_IP"
                if [ "$app_name" == "full" ]; then
                    result=$(scp "$LatestBackupFile" "$CFG_BACKUP_REMOTE_2_USER"@"$CFG_BACKUP_REMOTE_2_IP":"$CFG_BACKUP_REMOTE_2_BACKUP_DIRECTORY/full")
                    checkSuccess "Transfering $app_name backup to Remote Backup Host - $CFG_BACKUP_REMOTE_2_IP"
                elif [ "$app_name" != "full" ]; then
                    result=$(scp "$LatestBackupFile" "$CFG_BACKUP_REMOTE_2_USER"@"$CFG_BACKUP_REMOTE_2_IP":"$CFG_BACKUP_REMOTE_2_BACKUP_DIRECTORY/single")
                    checkSuccess "Transfering $app_name backup to Remote Backup Host - $CFG_BACKUP_REMOTE_2_IP"
                fi
            else
                checkSuccess "Testing SSH connection to $CFG_BACKUP_REMOTE_2_IP"
            fi
        else
            if [ "$app_name" == "full" ]; then
                result=$(sshpass -p "$CFG_BACKUP_REMOTE_2_PASS" scp "$LatestBackupFile" "$CFG_BACKUP_REMOTE_2_USER"@"$CFG_BACKUP_REMOTE_2_IP":"$CFG_BACKUP_REMOTE_2_BACKUP_DIRECTORY/full")
                checkSuccess "Transferring $app_name backup to Remote Backup Host - $CFG_BACKUP_REMOTE_2_IP"
            elif [ "$app_name" != "full" ]; then
                result=$(sshpass -p "$CFG_BACKUP_REMOTE_2_PASS" scp "$LatestBackupFile" "$CFG_BACKUP_REMOTE_2_USER"@"$CFG_BACKUP_REMOTE_2_IP":"$CFG_BACKUP_REMOTE_2_BACKUP_DIRECTORY/single")
                checkSuccess "Transferring $app_name backup to Remote Backup Host - $CFG_BACKUP_REMOTE_2_IP"
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