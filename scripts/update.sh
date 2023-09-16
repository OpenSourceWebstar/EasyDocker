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
    
    # Reset git
    result=$(sudo -u $easydockeruser rm -rf $script_dir)
    checkSuccess "Deleting all Git files"
    result=$(mkdirFolders "$script_dir")
    checkSuccess "Create the directory if it doesn't exist"
    cd "$script_dir"
    checkSuccess "Going into the install folder"
    result=$(sudo -u $easydockeruser git clone "$repo_url" "$script_dir" > /dev/null 2>&1)
    checkSuccess "Clone the Git repository"
    
    # Copy files back into the install folder
    result=$(copyFolders "$backup_install_dir/$backupFolder/" "$script_dir")
    checkSuccess "Copy the backed up folders back into the installation directory"
    
    # Zip up folder for safe keeping and remove folder
    result=$(sudo -u $easydockeruser zip -r "$backup_install_dir/$backupFolder.zip" "$backup_install_dir/$backupFolder")
    checkSuccess "Zipping up the the backup folder for safe keeping"
    result=$(sudo rm -rf "$backup_install_dir/$backupFolder")
    checkSuccess "Removing the backup folder"
    
    # Fixing the issue where the git does not use the .gitignore
    result=$(cd $script_dir)
    checkSuccess "Going into the install folder"
    sudo git config core.fileMode false
    sudo -u $easydockeruser git rm --cached $configs_dir/$config_file_backup > /dev/null 2>&1
    sudo -u $easydockeruser git rm --cached $configs_dir/$config_file_general > /dev/null 2>&1
    sudo -u $easydockeruser git rm --cached $configs_dir/$config_file_requirements > /dev/null 2>&1
    sudo -u $easydockeruser git rm --cached $configs_dir/$ip_file > /dev/null 2>&1
    sudo -u $easydockeruser find "$containers_dir" -type f -name '*.config' -exec git -C "$containers_dir" rm --cached -- {} \; > /dev/null 2>&1
    sudo -u $easydockeruser git rm --cached $logs_dir/$docker_log_file > /dev/null 2>&1
    sudo -u $easydockeruser git rm --cached $logs_dir/$backup_log_file > /dev/null 2>&1
    # Loop through the files in $containers_dir and identify config files
    for config_file in "$containers_dir"/*.config; do
        if [ -f "$config_file" ]; then
            # Remove the file from Git index (staging area)
            sudo -u $easydockeruser git rm --cached "$config_file" > /dev/null 2>&1
        fi
    done
    isSuccessful "Removing configs and logs from git for git changes"
    result=$(sudo -u $easydockeruser git commit -m "Stop tracking ignored files")
    checkSuccess "Removing tracking ignored files"
    
    isSuccessful "Custom changes have been discarded successfully"
    update_done=true
}