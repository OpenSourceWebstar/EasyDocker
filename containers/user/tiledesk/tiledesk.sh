#!/bin/bash

# Description : Tiledesk - Live Chat Platform *UNFINISHED* (c/u/s/r/i):

installTileDesk()
{
    app_name=$CFG_TILEDESK_APP_NAME
    setupInstallVariables $app_name;

    if [[ "$tiledesk" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

	if [[ "$tiledesk" == *[uU]* ]]; then
		uninstallApp $app_name;
	fi

	if [[ "$tiledesk" == *[sS]* ]]; then
		shutdownApp;
	fi

    if [[ "$tiledesk" == *[rR]* ]]; then
        dockerDownUpDefault $app_name;
    fi

    if [[ "$tiledesk" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###          Install $app_name"
        echo "##########################################"
        echo ""

		((menu_number++))
        echo ""
        echo "---- $menu_number. Checking custom DNS entry and IP for setup"
        echo ""

		setupIPsAndHostnames $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Pulling a default $app_name docker-compose.yml file."
        echo ""

		setupComposeFileApp;

		result=$(cd $install_dir$app_name && sudo curl https://raw.githubusercontent.com/Tiledesk/tiledesk-deployment/master/docker-compose/docker-compose.yml --output docker-compose.yml)
		checkSuccess "Downloading docker-compose.yml from $app_name GitHub"		

		whitelistApp $app_name false;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Updating file permissions before starting."
        echo ""

		fixPermissionsBeforeStart;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		if [[ "$OS" == [123] ]]; then
			if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
				result=$(runCommandForDockerInstallUser "docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml down")
				checkSuccess "Shutting down docker-compose.$app_name.yml"
				if [[ "$public" == "true" ]]; then
					result=$(runCommandForDockerInstallUser "EXTERNAL_BASE_URL="https://$domain_full" EXTERNAL_MQTT_BASE_URL="wss://$domain_full" docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml up -d")
					checkSuccess "Starting public docker-compose.$app_name.yml"
				else
					result=$(runCommandForDockerInstallUser "docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml up -d")
					checkSuccess "Starting standard docker-compose.$app_name.yml"
				fi
			elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
				result=$(sudo -u $easydockeruser docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml down)
				checkSuccess "Shutting down docker-compose.$app_name.yml"
				if [[ "$public" == "true" ]]; then
					result=$(EXTERNAL_BASE_URL="https://$domain_full" EXTERNAL_MQTT_BASE_URL="wss://$domain_full" sudo -u $easydockeruser docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml up -d)
					checkSuccess "Starting public docker-compose.$app_name.yml"
				else
					result=$(sudo -u $easydockeruser docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml up -d)
					checkSuccess "Starting standard docker-compose.$app_name.yml"
				fi
			fi
		fi

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Opening ports if required"
        echo ""

        openAppPorts $app_name;

		((menu_number++))
		echo ""
        echo "---- $menu_number. Adding $app_name to the Apps Database table."
        echo ""

		databaseInstallApp;

		((menu_number++))
        echo ""
        echo "---- $menu_number. You can find $app_name files at $install_dir$app_name"
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