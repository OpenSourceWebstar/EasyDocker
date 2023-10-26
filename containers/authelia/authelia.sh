#!/bin/bash

# Category : system
# Description : Authelia - Single Sign-On (c/u/s/r/i):

installAuthelia()
{
    local passedValue="$1"

    if [[ "$passedValue" == "install" ]]; then
        authelia=i
    fi

    if [[ "$authelia" == *[cCtTuUsSrRiI]* ]]; then
        setupConfigToContainer --silent authelia;
        local app_name=$CFG_AUTHELIA_APP_NAME
		setupInstallVariables $app_name;
    fi
    
    if [[ "$authelia" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

	if [[ "$authelia" == *[uU]* ]]; then
		uninstallApp $app_name;
	fi

	if [[ "$authelia" == *[sS]* ]]; then
		shutdownApp $app_name;
	fi

    if [[ "$authelia" == *[rR]* ]]; then
        if [[ $compose_setup == "default" ]]; then
		    dockerDownUpDefault $app_name;
        elif [[ $compose_setup == "app" ]]; then
            dockerDownUpAdditionalYML $app_name;
        fi
    fi

    if [[ "$authelia" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###      Install $app_name"
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
        echo "---- $menu_number. Pulling a default $app_name docker-compose.yml file."
        echo ""

        if [[ $compose_setup == "default" ]]; then
		    setupComposeFileNoApp $app_name;
        elif [[ $compose_setup == "app" ]]; then
            setupComposeFileApp $app_name;
        fi

        local result=$(sudo sed -i "s/theme: light/theme: $CFG_AUTHELIA_THEME/" "$containers_dir$app_name/config/config.template.yml")
        checkSuccess "Changing theme for $app_name to $CFG_AUTHELIA_THEME"

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		whitelistAndStartApp $app_name install;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Updating file permissions before starting."
        echo ""

		fixPermissionsBeforeStart $app_name;

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
        echo "    External : http://$public_ip:$usedport1/"
        echo "    Local : http://$ip_setup:$usedport1/"
        echo ""

		menu_number=0
        sleep 3s
        cd
	fi
	authelia=n
}