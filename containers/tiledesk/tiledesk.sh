#!/bin/bash

# Category : user
# Description : Tiledesk - Live Chat Platform *UNFINISHED* (c/u/s/r/i):

installTiledesk()
{
    local passedValue="$1"

    if [[ "$passedValue" == "install" ]]; then
        tiledesk=i
    fi

    if [[ "$tiledesk" == *[cCtTuUsSrRiI]* ]]; then
        setupConfigToContainer --silent tiledesk;
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
        if [[ $compose_setup == "default" ]]; then
		    dockerDownUpDefault $app_name;
        elif [[ $compose_setup == "app" ]]; then
            dockerDownUpAdditionalYML $app_name;
        fi
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

        setupConfigToContainer $app_name install;
        isSuccessful "Install folders and Config files have been setup for $app_name."

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Checking & Opening ports if required"
        echo ""

        checkAppPorts $app_name install;
		checkAllowOrDenyPorts;
        
		((menu_number++))
        echo ""
        echo "---- $menu_number. Pulling a default $app_name docker-compose.yml file."
        echo ""

        if [[ $compose_setup == "default" ]]; then
		    setupComposeFileNoApp $app_name;
        elif [[ $compose_setup == "app" ]]; then
            setupComposeFileApp $app_name;
        fi

		local result=$(cd $containers_dir$app_name && sudo curl https://raw.githubusercontent.com/Tiledesk/tiledesk-deployment/master/docker-compose/docker-compose.yml --output docker-compose.yml)
		checkSuccess "Downloading docker-compose.yml from $app_name GitHub"		

		whitelistAndStartApp $app_name install;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Updating file permissions before starting."
        echo ""

		fixPermissionsBeforeStart $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		if [[ "$OS" == [1234567] ]]; then
			if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
				local result=$(runCommandForDockerInstallUser "docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml down")
				checkSuccess "Shutting down docker-compose.$app_name.yml"
				if [[ "$public" == "true" ]]; then
					local result=$(runCommandForDockerInstallUser "EXTERNAL_BASE_URL="https://$domain_full" EXTERNAL_MQTT_BASE_URL="wss://$domain_full" docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml up -d")
					checkSuccess "Starting public docker-compose.$app_name.yml"
				else
					local result=$(runCommandForDockerInstallUser "docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml up -d")
					checkSuccess "Starting standard docker-compose.$app_name.yml"
				fi
			elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
				local result=$(sudo -u $easydockeruser docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml down)
				checkSuccess "Shutting down docker-compose.$app_name.yml"
				if [[ "$public" == "true" ]]; then
					local result=$(EXTERNAL_BASE_URL="https://$domain_full" EXTERNAL_MQTT_BASE_URL="wss://$domain_full" sudo -u $easydockeruser docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml up -d)
					checkSuccess "Starting public docker-compose.$app_name.yml"
				else
					local result=$(sudo -u $easydockeruser docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml up -d)
					checkSuccess "Starting standard docker-compose.$app_name.yml"
				fi
			fi
		fi

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
        echo "    Public : https://$host_setup/"
        echo "    External : http://$public_ip:$port/"
        echo "    Local : http://$ip_setup:$port/"
        echo ""
		    
		menu_number=0
        sleep 3s
        cd
	fi
	tiledesk=n
}