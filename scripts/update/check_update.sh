#!/bin/bash

checkUpdates()
{
    local param1="$1"
    
    gitCheckEasyDockerConfigFilesExist;
	sourceCheckFiles;

	if [[ $CFG_REQUIREMENT_UPDATES == "true" ]]; then
		echo ""
		echo "#####################################"
		echo "###      Checking for Updates     ###"
		echo "#####################################"
		echo ""

		databasePathInsert $initial_path_save;

        # DNS Query Test with Quad9
        isNotice "Testing internet DNS, please wait..."
        if dig +short @9.9.9.9 quad9.net >/dev/null; then
            isSuccessful "Internet DNS is working."
        else
            isError "Internet DNS is not working."
            exit 1
        fi

		cd "$script_dir" || { echo "Error: Cannot navigate to the repository directory"; exit 1; }

		# Update Git to ignore changes in file permissions
		sudo -u $sudo_user_name git config core.fileMode false
		# Update Git with email address
		sudo -u $sudo_user_name git config --global user.name "$CFG_INSTALL_NAME"
		sudo -u $sudo_user_name git config --global user.email "$CFG_EMAIL"

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
                        gitCheckEasyDockerConfigFilesExist;
                        gitCheckConfigs;
						fixPermissionsBeforeStart "" "update";
						sourceCheckFiles;

                        if [[ $init_run_flag == "run" ]]; then
                            isSuccessful "Starting/Restarting EasyDocker"
                            startLoad;
                        fi
						
						;;
					[nN])
						isNotice "Custom changes will be kept, continuing..."
                        remove_changes=false
                        gitCheckForUpdate;
                        gitCheckEasyDockerConfigFilesExist;
                        gitCheckConfigs;
						fixPermissionsBeforeStart "" "update";
						sourceCheckFiles;
                        
                        if [[ $init_run_flag == "run" ]]; then
                            startLoad;
                        fi
						
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
            gitCheckEasyDockerConfigFilesExist;
            gitCheckConfigs;
			fixPermissionsBeforeStart "" "update";
			sourceCheckFiles;

            if [[ $init_run_flag == "run" ]]; then
                isSuccessful "Starting/Restarting EasyDocker"
                startLoad;
            fi
		fi
	else
        if [[ $init_run_flag == "run" ]]; then
            startLoad;
        fi
	fi
}
