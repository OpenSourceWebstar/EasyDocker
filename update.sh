#!/bin/bash

path="$3"

source init.sh
source configs/config_requirements
source scripts/functions.sh
source scripts/variables.sh

checkUpdates()
{
	if [[ $CFG_REQUIREMENT_UPDATES == "true" ]]; then
		echo ""
		echo "#####################################"
		echo "###      Checking for Updates     ###"
		echo "#####################################"
		echo ""

		update_done=false
		cd "$script_dir" || { echo "Error: Cannot navigate to the repository directory"; exit 1; }

		result=$(git config core.fileMode false)
		checkSuccess "Update Git to ignore changes in file permissions"

		# Check if there are uncommitted changes
		if [[ $(git status --porcelain) ]]; then
			isNotice "There are uncommitted changes in the repository."
			while true; do
				isQuestion "Do you want to discard these changes and update the repository? (y/n): "
				read -p "" customupdatesfound
				case $customupdatesfound in
					[yY])
						gitFolderResetAndBackup;
						reloadScripts;

						isSuccessful "Starting/Restarting EasyDocker"
						exit 0 ; runStart
						;;
					[nN])
						isNotice "Custom changes will be kept, continuing..."
						continue;
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
			reloadScripts;

			isSuccessful "Starting/Restarting EasyDocker"
			exit 0 ; runStart
		fi
	else
		exit 0 ; runStart
	fi
}

gitFolderResetAndBackup()
{
    # Folder setup
    # Check if the directory specified in $script_dir exists
    if [ ! -d "$backup_install_dir/$backupFolder" ]; then
        isNotice "Directory '$backup_install_dir/$backupFolder' does not exist. Creating it..."
        result=$(mkdir -p "$backup_install_dir/$backupFolder")
        checkSuccess "Create the backup folder"
    fi
    result=$(cd $backup_install_dir)
    checkSuccess "Going into the backup install folder"

    # Copy folders
    result=$(cp -r "$configs_dir" "$backup_install_dir/$backupFolder")
    checkSuccess "Copy the configs to the backup folder"
    result=$(cp -r "$logs_dir" "$backup_install_dir/$backupFolder")
    checkSuccess "Copy the logs to the backup folder"

    # Reset git
    result=$(rm -rf $script_dir)
    checkSuccess "Deleting all Git files"
    result=$(mkdir -p "$script_dir")
    checkSuccess "Create the directory if it doesn't exist"	
    cd "$script_dir" || exit 1
    checkSuccess "Go to the install folder"	
	result=$(git clone "$repo_url" "$script_dir")
    checkSuccess "Clone the Git repository"

    # Copy folders back into the install folder
    result=$(cp -rf "$backup_install_dir/$backupFolder/"* "$script_dir")
    checkSuccess "Copy the backed up folders back into the installation directory"

    # Zip up folder for safe keeping and remove folder
    result=$(zip -r "$backup_install_dir/$backupFolder.zip" "$backup_install_dir/$backupFolder")
    checkSuccess "Zipping up the the backup folder for safe keeping"
    result=$(rm -r "$backup_install_dir/$backupFolder")
    checkSuccess "Removing the backup folder"

    # Fixing the issue where the git does not use the .gitignore
    result=$(cd $script_dir)
    checkSuccess "Going into the install folder"
    git rm --cached $configs_dir/config_apps 
    git rm --cached $configs_dir/config_backup 
    git rm --cached $configs_dir/config_general 
    git rm --cached $configs_dir/config_requirements 
    git rm --cached $configs_dir/config_migrate 
    git rm --cached $logs_dir/easydocker.log 
    git rm --cached $logs_dir/backup.log
    isSuccessful "Removing configs and logs from git for git changes"
    result=$(git commit -m "Stop tracking ignored files")
    checkSuccess "Removing tracking ignored files"

	isSuccessful "Custom changes have been discarded successfully"
	update_done=true
}

exitScript() {
	echo ""
	echo ""
	isNotice "Exiting script..."
	echo ""
	isNotice "Last working path :"
	isNotice "cd $initial_path_save"
	echo ""
	exit 0
}

checkUpdates;