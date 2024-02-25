#!/bin/bash

# Category : system
# Description : Watchtower - Docker Updater (c/u/s/r/i):

installWatchtower()
{
    if [[ "$watchtower" == *[cCtTuUsSrRiI]* ]]; then
        dockerConfigSetupToContainer silent watchtower;
        local app_name=$CFG_WATCHTOWER_APP_NAME
		setupInstallVariables $app_name;
    fi

    if [[ "$watchtower" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

    if [[ "$watchtower" == *[uU]* ]]; then
        dockerUninstallApp $app_name;
    fi

    if [[ "$watchtower" == *[sS]* ]]; then
        dockerComposeDown $app_name;
    fi

    if [[ "$watchtower" == *[rR]* ]]; then
        dockerComposeRestart $app_name;
    fi

    if [[ "$watchtower" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###           Install $app_name"
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

        dockerComposeRestartFile $app_name;

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
    
		menu_number=0
        sleep 3s
        cd
    fi
    watchtower=n
}