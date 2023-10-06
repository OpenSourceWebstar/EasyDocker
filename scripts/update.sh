#!/bin/bash

checkUpdates()
{

    gitCheckConfigFilesExist;
	sourceScripts "update";

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

        # Check if there are edited (modified) files
        if git status --porcelain | grep -q "^ M"; then
			isNotice "There are uncommitted changes in the repository."
			while true; do
				isQuestion "Do you want to discard these changes and update the repository? (y/n): "
				read -p "" customupdatesfound
				case $customupdatesfound in
					[yY])
                        remove_changes=true
                        gitCheckForUpdate;
                        gitCheckConfigFilesExist;
                        gitCheckConfigs;
						fixPermissionsBeforeStart "" "update";
						sourceScripts "update";

						isSuccessful "Starting/Restarting EasyDocker"
						detectOS;
						
						;;
					[nN])
						isNotice "Custom changes will be kept, continuing..."
                        remove_changes=false
                        gitCheckForUpdate;
                        gitCheckConfigFilesExist;
                        gitCheckConfigs;
						fixPermissionsBeforeStart "" "update";
						sourceScripts "update";
                        
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
            gitCheckForUpdate;
            gitCheckConfigFilesExist;
            gitCheckConfigs;
			fixPermissionsBeforeStart "" "update";
			sourceScripts "update";

			isSuccessful "Starting/Restarting EasyDocker"
			detectOS;
		fi
	else
		detectOS;
	fi
}

gitCheckConfigFilesExist()
{
    local file_found_count=0

    for file in "${config_files_all[@]}"; do
        local file_path="$install_configs_dir$file"
        if [ -f "$file_path" ]; then
            if [ ! -f "$configs_dir$file" ]; then
                copyFile --silent "$file_path" "$configs_dir$file"
            #else
                #isNotice "Config File $file already exists in $configs_dir. Skipping."
            fi
            ((file_found_count++))
        else
            isNotice "Config File $file does not exist in $configs_dir."
        fi
    done
    
    if [ "$file_found_count" -eq "${#config_files_all[@]}" ]; then
        isSuccessful "All config files are successfully set up in the configs folder."
    else
        isFatalErrorExit "Not all config files were found in $configs_dir."
    fi
}


gitCheckConfigs() 
{
    if grep -q "Change-Me" "$configs_dir/$config_file_general"; then
        #echo "Local configuration file contains 'Change-Me'."
        # Flag to track if any valid configs were found
        local valid_configs_found=false

        # Get a list of all backup zip files in the directory, sorted by date (latest first)
        local backup_files=($(sudo find "$backup_install_dir" -type f -name 'backup_*.zip' | sort -r))
        
        # Check if any backup files were found
        if [ ${#backup_files[@]} -eq 0 ]; then
            isNotice "No valid configs found in any backup file OR they all contain default values."
            while true; do
                isQuestion "Do you want to continue without a config backup? (y/n): "
                read -rp " " acceptnoconfigs
                if [[ "$acceptnoconfigs" =~ ^[yY]$ ]]; then
                    break
                elif [[ "$acceptnoconfigs" =~ ^[nN]$ ]]; then
                    echo ""
                    echo ""
                    isNotice "Place your EasyDocker install backup file into $backup_install_dir and run the 'easydocker' command."
                    exitScript
                    exit;
                else
                    isNotice "Please provide a valid input (y/n)."
                fi
            done
            return
        fi

        for zip_file in "${backup_files[@]}"; do
            #echo "Processing backup file: $zip_file"
            # Create a temporary directory to extract the zip file contents
            local temp_dir=$(mktemp -d)

            # Extract the zip file contents
            unzip -q "$zip_file" -d "$temp_dir"

            # Find the path of $config_file_general within the extracted files
            local config_file_path=$(sudo find "$temp_dir" -type f -name "$config_file_general")

            # Check if $config_file_general exists and does not contain "Change-Me"
            if [ -n "$config_file_path" ] && ! grep -q "Change-Me" "$config_file_path"; then
                local valid_configs_found=true
                isSuccessful "Valid config found in backup file: $zip_file"
                while true; do
                    isQuestion "Do you want to restore the latest config backup? (y/n): "
                    read -p "" defaultconfigfound
                    case $defaultconfigfound in
                        [yY])
                            gitUseExistingBackup $zip_file
                            # Set the flag to exit the loop
                            break 2  # Exit the outer loop as well
                            ;;
                        [nN])
                            isNotice "Custom changes will be kept, continuing..."
                            break
                            ;;
                        *)
                            isNotice "Please provide a valid input (y or n)."
                            ;;
                    esac
                done
            #else
                #echo "Config file not found or contains 'Change-Me' in backup file: $zip_file"
            fi

            # Clean up the temporary directory
            rm -rf "$temp_dir"
        done

        # If no valid configs were found in any backup file, display a message
        if [ "$valid_configs_found" = false ]; then
            if [[ $acceptupdates != [nN] ]]; then
                isNotice "No valid configs found in any backup file OR they all contain default values."
                while true; do
                    isQuestion "Do you want to continue without a config backup? (y/n): "
                    read -rp "" acceptnoconfigs
                    if [[ "$acceptnoconfigs" =~ ^[yYnN]$ ]]; then
                        break
                    fi
                    isNotice "Please provide a valid input (y/n)."
                done
                if [[ $acceptnoconfigs == [nN] ]]; then
                    echo ""
                    echo ""
                    isNotice "Place your EasyDocker install backup file into $backup_install_dir and run the 'easydocker' command."
                    exitScript
                    exit
                fi
            fi
        fi
    fi
}

gitCheckForUpdate()
{
    # Check the status of the local repository
    cd "$script_dir"
    sudo -u $easydockeruser git fetch > /dev/null 2>&1
    if sudo -u $easydockeruser git status | grep -q "Your branch is ahead"; then
        isSuccessful "The repository is up to date...continuing..."
    elif sudo -u $easydockeruser git status | grep -q "Your branch is up to date with"; then
        isSuccessful "The repository is up to date...continuing..."
    else
        isNotice "Updates found."
        while true; do
            isQuestion "Do you want to update EasyDocker now? (y/n): "
            read -rp "" acceptupdates
            if [[ "$acceptupdates" =~ ^[yYnN]$ ]]; then
                break
            fi
            isNotice "Please provide a valid input (y/n)."
        done
        if [[ $acceptupdates == [yY] ]]; then
            gitFolderResetAndBackup;
        fi
    fi
}

gitUseExistingBackup()
{
    echo ""
    echo "#####################################"
    echo "###  Installing EasyDocker Backup ###"
    echo "#####################################"
    echo ""
    local backup_file="$1"
    local backup_file_without_zip=$(basename "$backup_file" .zip)
    update_done=false
    
    local result=$(sudo unzip -o $backup_file -d $backup_install_dir)
    checkSuccess "Copy the configs to the backup folder"

    gitReset;
    
    local result=$(copyFolders "$backup_install_dir$backup_install_dir/$backup_file_without_zip/" "$docker_dir")
    checkSuccess "Copy the backed up folders back into the installation directory"

    gitCleanInstallBackups;

    gitUntrackFiles;

    isSuccessful "Custom changes have been discarded successfully"

    echo ""
    isNotice "You have restored the configuration files for EasyDocker."
    isNotice "To avoid any issues please rerun the 'easydocker' command to make sure all new configs are loaded."
    echo ""
    exit
    update_done=true
}

gitFolderResetAndBackup()
{
    echo ""
    echo "#####################################"
    echo "###      Updating EasyDocker      ###"
    echo "#####################################"
    echo ""
    update_done=false

    if [ ! -d "$backup_install_dir/$backupFolder" ]; then
        local result=$(mkdirFolders "$backup_install_dir/$backupFolder")
        checkSuccess "Create the backup folder"
    fi
    local result=$(cd $backup_install_dir)
    checkSuccess "Going into the backup install folder"

    local result=$(copyFolder "$configs_dir" "$backup_install_dir/$backupFolder")
    checkSuccess "Copy the configs to the backup folder"
    local result=$(copyFolder "$logs_dir" "$backup_install_dir/$backupFolder")
    checkSuccess "Copy the logs to the backup folder"
    
    gitReset;
    
    local result=$(copyFolders "$backup_install_dir/$backupFolder/" "$docker_dir")
    checkSuccess "Copy the backed up folders back into the installation directory"

    local result=$(sudo -u $easydockeruser zip -r "$backup_install_dir/$backupFolder.zip" "$backup_install_dir/$backupFolder")
    checkSuccess "Zipping up the the backup folder for safe keeping"

    gitCleanInstallBackups;

    gitUntrackFiles;

    isSuccessful "Custom changes have been discarded successfully"
    echo ""
    isNotice "You have updated your version of EasyDocker."
    isNotice "To avoid any issues please rerun the 'easydocker' command to make sure all new changes are loaded."
    echo ""
    exit
    update_done=true
}

gitUntrackFiles()
{
    # Fixing the issue where the git does not use the .gitignore
    cd $script_dir
    sudo git config core.fileMode false
    isSuccessful "Removing configs and logs from git for git changes"
    local result=$(sudo -u $easydockeruser git commit -m "Stop tracking ignored files")
    checkSuccess "Removing tracking ignored files"
}

gitReset()
{
    # Reset git
    local result=$(sudo -u $easydockeruser rm -rf $script_dir)
    checkSuccess "Deleting all Git files"
    local result=$(mkdirFolders "$script_dir")
    checkSuccess "Create the directory if it doesn't exist"
    cd "$script_dir"
    checkSuccess "Going into the install folder"
    local result=$(sudo -u $easydockeruser git clone "$repo_url" "$script_dir" > /dev/null 2>&1)
    checkSuccess "Clone the Git repository"
}

gitCleanInstallBackups()
{
    local result=$(sudo find "$backup_install_dir" -mindepth 1 -type f ! -name '*.zip' -o -type d ! -name '*.zip' -exec sudo rm -rf {} +)
    checkSuccess "Cleaning up install backup folders."
    local result=$(cd "$backup_install_dir" && sudo find . -maxdepth 1 -type f -name '*.zip' | sudo xargs ls -t | tail -n +6 | sudo xargs -r rm)
    checkSuccess "Deleting old install backup and keeping the latest 5."
}