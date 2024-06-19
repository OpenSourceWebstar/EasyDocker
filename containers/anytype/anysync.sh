#!/bin/bash

# Category : Privacy
# Description : Anysync - Personal Knowledge Base (c/u/s/r/i):

install()
{
    if [[ "$anysync" == *[cCtTuUsSrRiI]* ]]; then
        dockerConfigSetupToContainer silent anysync;
        local app_name=$CFG_ANYSYNC_APP_NAME
		setupInstallVariables $app_name;
    fi
    
    if [[ "$anysync" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

	if [[ "$anysync" == *[uU]* ]]; then
		dockerUninstallApp $app_name;
	fi

	if [[ "$anysync" == *[sS]* ]]; then
		dockerComposeDown $app_name;
	fi

    if [[ "$anysync" == *[rR]* ]]; then
        dockerComposeRestart $app_name;
    fi

    if [[ "$anysync" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###      Install $app_name"
        echo "##########################################"
        echo ""
        
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
        echo "---- $menu_number. Pulling $app_name Git repo"
        echo ""

        backupContainerFilesToTemp $app_name;
        local result=$(sudo rm -rf $containers_dir$app_name)
		checkSuccess "Removing $app_name install folder"

        local result=$(sudo -u $docker_install_user git clone $CFG_ANYSYNC_GIT $containers_dir$app_name)
		checkSuccess "Cloning $app_name Git"
        backupContainerFilesRestore $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Generating the .env file file."
        echo ""
        
        cd $containers_dir$app_name
        local result=$(docker buildx build --tag generateconfig-env --file Dockerfile-generateconfig-env .)
        local result=$(docker run --rm --volume $containers_dir$app_name/:/code/ generateconfig-env)

		((menu_number++))
        echo ""
        echo "---- $menu_number. Setting up the $app_name docker-compose.yml file."
        echo ""

        dockerComposeSetupFile $app_name;

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
        echo "    You can now navigate to your new service using one of the options below : "
        echo ""
        
        menuShowFinalMessages $app_name;

		menu_number=0
        sleep 3s
        cd
	fi
	anysync=n
}