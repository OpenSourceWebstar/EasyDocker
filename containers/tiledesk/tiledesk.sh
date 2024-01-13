#!/bin/bash

# Category : user
# Description : Tiledesk - Live Chat Platform *UNFINISHED* (c/u/s/r/i):

installTiledesk()
{
    if [[ "$tiledesk" == *[cCtTuUsSrRiI]* ]]; then
        setupConfigToContainer silent tiledesk;
		local app_name=$CFG_TILEDESK_APP_NAME
		setupInstallVariables $app_name;
	fi

    if [[ "$tiledesk" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

	if [[ "$tiledesk" == *[uU]* ]]; then
		uninstallApp $app_name;
	fi

	if [[ "$tiledesk" == *[sS]* ]]; then
		shutdownApp $app_name;
	fi

    if [[ "$tiledesk" == *[rR]* ]]; then
        dockerDownUp $app_name;
    fi

    if [[ "$tiledesk" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###          Install $app_name"
        echo "##########################################"
        echo ""

		((menu_number++))
        echo ""
        echo "---- $menu_number. Setting up install folder and config file for $app_name."
        echo ""

        setupConfigToContainer "loud" "$app_name" "install";
        isSuccessful "Install folders and Config files have been setup for $app_name."

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Checking & Opening ports if required"
        echo ""

        checkAppPorts $app_name install;
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
        echo "---- $menu_number. Setting up the $app_name docker-compose.yml file."
        echo ""

        setupComposeFile $app_name;

		local result=$(cd $containers_dir$app_name && sudo curl https://raw.githubusercontent.com/Tiledesk/tiledesk-deployment/master/docker-compose/docker-compose.yml --output docker-compose.yml)
		checkSuccess "Downloading docker-compose.yml from $app_name GitHub"		
		
        ((menu_number++))
        echo ""
        echo "---- $menu_number. Updating file permissions before starting."
        echo ""

		fixPermissionsBeforeStart $app_name;
		((menu_number++))
        
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		dockerUpdateAndStartApp $app_name install;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		if [[ "$OS" == [1234567] ]]; then
			if [[ $CFG_DOCKER_INSTALL_TYPE== "rootless" ]]; then
				local result=$(runCommandForDockerInstallUser "docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml down")
				checkSuccess "Shutting down docker-compose.$app_name.yml"
				if [[ "$public" == "true" ]]; then
					local result=$(runCommandForDockerInstallUser "EXTERNAL_BASE_URL="https://$domain_full" EXTERNAL_MQTT_BASE_URL="wss://$domain_full" docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml up -d")
					checkSuccess "Starting public docker-compose.$app_name.yml"
				else
					local result=$(runCommandForDockerInstallUser "docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml up -d")
					checkSuccess "Starting standard docker-compose.$app_name.yml"
				fi
			elif [[ $CFG_DOCKER_INSTALL_TYPE== "root" ]]; then
				local result=$(sudo -u $sudo_user_name docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml down)
				checkSuccess "Shutting down docker-compose.$app_name.yml"
				if [[ "$public" == "true" ]]; then
					local result=$(EXTERNAL_BASE_URL="https://$domain_full" EXTERNAL_MQTT_BASE_URL="wss://$domain_full" sudo -u $sudo_user_name docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml up -d)
					checkSuccess "Starting public docker-compose.$app_name.yml"
				else
					local result=$(sudo -u $sudo_user_name docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml up -d)
					checkSuccess "Starting standard docker-compose.$app_name.yml"
				fi
			fi
		fi

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Running Application specific updates (if required)"
        echo ""

        updateApplicationSpecifics $app_name;

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
	tiledesk=n
}