#!/bin/bash

checkUpdates()
{
	if [[ $CFG_REQUIREMENT_UPDATES == "true" ]]; then
		echo ""
		echo "#####################################"
		echo "###      Checking for Updates     ###"
		echo "#####################################"
		echo ""

		databasePathInsert $initial_path;

		# Internet Test
		isNotice "Testing internet, please wait..."
		if sudo ping -c 4 "9.9.9.9" > /dev/null; then
			isSuccessful "Internet connectivity is working."
		else
			isError "Internet connectivity is not working."
			exit 1
		fi

		cd "$script_dir" || { echo "Error: Cannot navigate to the repository directory"; exit 1; }

		# Update Git to ignore changes in file permissions
		sudo -u $easydockeruser git config core.fileMode false
		# Update Git with email address
		sudo -u $easydockeruser git config --global user.name "$CFG_INSTALL_NAME"
		sudo -u $easydockeruser git config --global user.email "$CFG_EMAIL"

		# Check if there are uncommitted changes
		if [[ $(git status --porcelain) ]]; then
			isNotice "There are uncommitted changes in the repository."
			while true; do
				isQuestion "Do you want to discard these changes and update the repository? (y/n): "
				read -p "" customupdatesfound
				case $customupdatesfound in
					[yY])
						gitFolderResetAndBackup;
						fixFolderPermissions;
						sourceScripts;

						isSuccessful "Starting/Restarting EasyDocker"
						detectOS;
						
						;;
					[nN])
						isNotice "Custom changes will be kept, continuing..."
                        detectOS;
						
						;;
					*)
						isNotice "Please provide a valid input (y or n)."
						;;
				esac
			done
		fi

		# Make sure an update happens after custom code check
		if [[ $update_done != "true" ]]; then
			gitFolderResetAndBackup;
			fixFolderPermissions;
			sourceScripts;

			isSuccessful "Starting/Restarting EasyDocker"
			detectOS;
		fi
	else
		detectOS;
	fi
}

gitCheckConfigs()
{
    # If it's default config
    if grep -q "Change-Me" "$configs_dir/$config_file_general"; then
        # Check if any .zip files exist in the folder
        if [ "$(find "$folder" -type f -name 'backup_*.zip' | wc -l)" -gt 0 ]; then
            # Get the most recent .zip file based on the file name
            most_recent_zip="$(find "$folder" -type f -name 'backup_*.zip' | sort | tail -n 1)"
			isNotice "Default config values have been found, but a config backup has been found."
			while true; do
				isQuestion "Do you want to restore the latest config backup? (y/n): "
				read -p "" defaultconfigound
				case $defaultconfigound in
					[yY])
                        gitUseExistingBackup $most_recent_zip;
						;;
					[nN])
						isNotice "Custom changes will be kept, continuing..."
                        continue
						;;
					*)
						isNotice "Please provide a valid input (y or n)."
						;;
				esac
			done
            echo "The most recent config backup file is: $most_recent_zip"
        fi
    else
        gitFolderResetAndBackup;
    fi
}

gitUseExistingBackup()
{
    local backup_file="$1"
    local backup_file_without_zip=$(basename "$backup_file" .zip)
    update_done=false
    
    # Copy folders
    result=$(sudo unzip -o $backup_file -d $backup_install_dir)
    checkSuccess "Copy the configs to the backup folder"
    # Move files into the install folder
    result=$(mv "$backup_install_dir$backup_install_dir$backup_file_without_zip" "$backup_install_dir")
    checkSuccess "Copy the backed up folders back into the installation directory"
    result=$(cd $backup_install_dir && sudo rm -rf ./docker)
    checkSuccess "Remove unneeded folder after extraction"

    gitReset;
    
    # Copy files back into the install folder
    result=$(copyFolders "$backup_install_dir/$backup_file_without_zip/" "$script_dir")
    checkSuccess "Copy the backed up folders back into the installation directory"
    
    # Find and remove all files and folders except .zip files
    result=$(sudo find "$backup_install_dir" -mindepth 1 -type f ! -name '*.zip' -o -type d ! -name '*.zip' -exec sudo rm -rf {} +)
    checkSuccess "Cleaning up install backup folders."
    # Delete all zip files except the latest 5
    result=$(cd "$backup_install_dir" && sudo find . -maxdepth 1 -type f -name '*.zip' | sudo xargs ls -t | tail -n +6 | sudo xargs rm)
    checkSuccess "Cleaning up install backup folders."

    gitUntrackFiles;

    isSuccessful "Custom changes have been discarded successfully"
    update_done=true
}

gitFolderResetAndBackup()
{
    update_done=false
    # Folder setup
    # Check if the directory specified in $script_dir exists
    if [ ! -d "$backup_install_dir/$backupFolder" ]; then
        result=$(mkdirFolders "$backup_install_dir/$backupFolder")
        checkSuccess "Create the backup folder"
    fi
    result=$(cd $backup_install_dir)
    checkSuccess "Going into the backup install folder"

    # Copy folders
    result=$(copyFolder "$configs_dir" "$backup_install_dir/$backupFolder")
    checkSuccess "Copy the configs to the backup folder"
    result=$(copyFolder "$logs_dir" "$backup_install_dir/$backupFolder")
    checkSuccess "Copy the logs to the backup folder"
    # Use find to locate files and folders ending with ".config" and copy them to the temporary directory
    result=$(sudo rsync -av --include='*/' --include='*.config' --exclude='*' "$containers_dir" "$backup_install_dir/$backupFolder/containers")
    checkSuccess "Copy the containers to the backup folder"

    gitReset;
    
    # Copy files back into the install folder
    result=$(copyFolders "$backup_install_dir/$backupFolder/" "$script_dir")
    checkSuccess "Copy the backed up folders back into the installation directory"
    
    # Zip up folder for safe keeping and remove folder
    result=$(sudo -u $easydockeruser zip -r "$backup_install_dir/$backupFolder.zip" "$backup_install_dir/$backupFolder")
    checkSuccess "Zipping up the the backup folder for safe keeping"
    # Find and remove all files and folders except .zip files
    result=$(sudo find "$backup_install_dir" -mindepth 1 -type f ! -name '*.zip' -o -type d ! -name '*.zip' -exec sudo rm -rf {} +)
    checkSuccess "Cleaning up install backup folders."
    # Delete all zip files except the latest 5
    result=$(cd "$backup_install_dir" && sudo find . -maxdepth 1 -type f -name '*.zip' | sudo xargs ls -t | tail -n +6 | sudo xargs rm)
    checkSuccess "Cleaning up install backup folders."

    gitUntrackFiles;

    isSuccessful "Custom changes have been discarded successfully"
    update_done=true
}

gitUntrackFiles()
{
    # Fixing the issue where the git does not use the .gitignore
    cd $script_dir
    sudo git config core.fileMode false
    sudo -u $easydockeruser git rm --cached $configs_dir/$config_file_backup > /dev/null 2>&1
    sudo -u $easydockeruser git rm --cached $configs_dir/$config_file_general > /dev/null 2>&1
    sudo -u $easydockeruser git rm --cached $configs_dir/$config_file_requirements > /dev/null 2>&1
    sudo -u $easydockeruser git rm --cached $configs_dir/$ip_file > /dev/null 2>&1
    sudo -u $easydockeruser git rm --cached $logs_dir/$docker_log_file > /dev/null 2>&1
    sudo -u $easydockeruser git rm --cached $logs_dir/$backup_log_file > /dev/null 2>&1
    sudo -u $easydockeruser git clean -f "*.config" > /dev/null 2>&1
    isSuccessful "Removing configs and logs from git for git changes"
    result=$(sudo -u $easydockeruser git commit -m "Stop tracking ignored files")
    checkSuccess "Removing tracking ignored files"
}

gitReset()
{
    # Reset git
    result=$(sudo -u $easydockeruser rm -rf $script_dir)
    checkSuccess "Deleting all Git files"
    result=$(mkdirFolders "$script_dir")
    checkSuccess "Create the directory if it doesn't exist"
    cd "$script_dir"
    checkSuccess "Going into the install folder"
    result=$(sudo -u $easydockeruser git clone "$repo_url" "$script_dir" > /dev/null 2>&1)
    checkSuccess "Clone the Git repository"
}