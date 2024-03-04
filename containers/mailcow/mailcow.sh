#!/bin/bash

# Category : privacy
# Description : Mailcow - Mail Server (c/u/s/r/i):

installMailcow()
{
    if [[ "$mailcow" == *[cCtTuUsSrRiI]* ]]; then
    	dockerConfigSetupToContainer silent mailcow;
		local app_name=$CFG_MAILCOW_APP_NAME
		local easy_setup=$CFG_MAILCOW_EASY_SETUP
		setupInstallVariables $app_name;
	fi

    if [[ "$mailcow" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

	if [[ "$mailcow" == *[uU]* ]]; then
		dockerUninstallApp $app_name;
	fi

	if [[ "$mailcow" == *[sS]* ]]; then
		dockerComposeDown $app_name;
	fi

	if [[ "$mailcow" == *[rR]* ]]; then
        dockerComposeRestart $app_name;
	fi

    if [[ "$mailcow" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###           Install $app_name"
        echo "##########################################"
        echo ""

		((menu_number++))
        echo ""
        echo "---- $menu_number. Checking if $app_name can be installed."
        echo ""

        dockerCheckAllowedInstall "$app_name" || return 1

		((menu_number++))
        echo ""
        echo "---- $menu_number. Setting up install folder and config file for $app_name."
        echo ""

        dockerConfigSetupToContainer "loud" "$app_name" "install";
        isSuccessful "Install folders and Config files have been setup for $app_name."

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Checking & Opening ports if required"
        echo ""

        portsCheckApp $app_name install;
        if [[ $disallow_used_port == "true" ]]; then
            isError "A used port conflict has occured, setup is cancelling..."
            disallow_used_port=""
            return
        else
            isSuccessful "No used port conflicts found, setup is continuing..."
        fi
        if [[ $disallow_open_port == "true" ]]; then
            isError "An open port conflict has occured, setup is cancelling..."
            disallow_open_port=""
            return
        else
            isSuccessful "No open port conflicts found, setup is continuing..."
        fi
        
		((menu_number++))
	    echo ""
        echo "---- $menu_number. Pulling Mailcow GitHub repo into the $containers_dir$app_name folder"
        echo ""

		mailcowSetupGit()
		{
			# Define the paths
			local mailcow_source_dir="$containers_dir$app_name"  # Directory with existing content
			local mailcow_backup_dir="/tmp/mailcow_backup"  # Temporary backup directory
			# Create a backup of the existing content
			if [ -d "$mailcow_source_dir" ]; then
				result=$(sudo mv "$mailcow_source_dir" "$mailcow_backup_dir")
				checkSuccess "Backup of existing content created"
			fi
			# Clone the Git repository
			local result=$(sudo rm -rf "$mailcow_source_dir")
			checkSuccess "Deleting mailcow directory git."
			local result=$(sudo -u $CFG_DOCKER_INSTALL_USER git clone https://github.com/mailcow/mailcow-dockerized "$mailcow_source_dir" && sudo -u $CFG_DOCKER_INSTALL_USER git config --global --add safe.directory $containers_dir$app_name)
			checkSuccess "Cloning Mailcow Dockerized GitHub repo"
			# Restore the backup content
			if [ -d "$mailcow_backup_dir" ]; then
				result=$(sudo rsync -a "$mailcow_backup_dir/" "$mailcow_source_dir/")
				checkSuccess "Restored existing content from backup"
				local result=$(sudo rm -rf "$mailcow_backup_dir")
				checkSuccess "Deleting backup directory."
			fi
		}

		if [ -f "$containers_dir$app_name/mailcow.conf" ]; then
			while true; do
				echo ""
				isNotice "Mailcow install already found."
				echo ""
				isQuestion "Would you like to reinstall $app_name? *THIS WILL WIPE ALL DATA* (y/n): "
				read -p "" reinstall_choice
				if [[ -n "$reinstall_choice" ]]; then
					break
				fi
				isNotice "Please provide a valid input."
			done
			if [[ "$reinstall_choice" == [yY] ]]; then
				mailcowSetupGit;
			fi
		else
			mailcowSetupGit;
		fi
        
		((menu_number++))
        echo ""
        echo "---- $menu_number. Pulling a $app_name docker-compose.yml file."
        echo ""

        dockerComposeRestartFile $app_name;

		local result=$(cd $containers_dir$app_name && sudo -u $CFG_DOCKER_INSTALL_USER ./generate_config.sh)
		checkSuccess "Running Mailcow config generation script"

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running configuration edits to mailserver.conf"
        echo ""

		if [ -e "$containers_dir$app_name/mailcow.conf" ]; then
			local result=$(sudo sed -i 's/HTTP_PORT=80/HTTP_PORT='$usedport1'/' $containers_dir$app_name/mailcow.conf)
			checkSuccess "Updating the mailserver.conf to custom http port"

			local result=$(sudo sed -i 's/HTTPS_PORT=443/HTTPS_PORT='$usedport2'/' $containers_dir$app_name/mailcow.conf)
			checkSuccess "Updating the mailserver.conf to custom https port"

			while true; do
				isQuestion "Would you like to disable Lets Encrypt? *RECOMMENDED* (y/n): "
				read -p "" lets_encrypt_choice
				if [[ -n "$lets_encrypt_choice" ]]; then
					break
				fi
				isNotice "Please provide a valid input."
			done
			if [[ "$lets_encrypt_choice" == [yY] ]]; then
				local result=$(sudo sed -i 's/SKIP_LETS_ENCRYPT=n/SKIP_LETS_ENCRYPT=y/' $containers_dir$app_name/mailcow.conf)
				checkSuccess "Updating the mailserver.conf to disable SSL install"
			fi

			while true; do
				isQuestion "Would you like to disable ClamD Antivirus? *Resource Reduction* (y/n): "
				read -p "" clamd_antivirus_choice
				if [[ -n "$clamd_antivirus_choice" ]]; then
					break
				fi
				isNotice "Please provide a valid input."
			done
			if [[ "$clamd_antivirus_choice" == [yY] ]]; then
				local result=$(sudo sed -i 's/SKIP_CLAMD=n/SKIP_CLAMD=y/' $containers_dir$app_name/mailcow.conf)
				checkSuccess "Updating the mailserver.conf to disable ClamD Antivirus"
			fi
		else
			isError "The file $mailcow_conf_file does not exist. Config generation has failed, please reinstall mailcow and try again."
            return
		fi

		((menu_number++))
        echo ""
        echo "---- $menu_number. Updating file permissions before starting."
        echo ""

		fixPermissionsBeforeStart $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		dockerComposeUpdateAndStartApp $app_name install;

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Running Application specific updates (if required)"
        echo ""

        appUpdateSpecifics $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running Headscale setup (if required)"
        echo ""

		setupHeadscale $app_name;

		((menu_number++))
		echo ""
        echo "---- $menu_number. Adding $app_name to the Apps Database table."
        echo ""

		databaseInstallApp $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. You can find $app_name files at $containers_dir$app_name"
        echo ""
        echo "    You can now navigate to your $app_name service using any of the options below : "
        echo ""
		
        menuShowFinalMessages $app_name;
      
		menu_number=0
        sleep 3s
        cd
    fi
	mailcow=n
}