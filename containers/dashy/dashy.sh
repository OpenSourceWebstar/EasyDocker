#!/bin/bash

# Category : system
# Description : Dashy - Docker Dashboard (c/t/u/s/r/i):

installDashy()
{
    passedValue="$1"

    if [[ "$passedValue" == "install" ]]; then
        dashy=i
    fi

    if [[ "$dashy" == *[cCtTuUsSrRiI]* ]]; then
        setupConfigToContainer dashy;
        app_name=$CFG_DASHY_APP_NAME
		setupInstallVariables $app_name;
    fi

    if [[ "$dashy" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

    if [[ "$dashy" == *[tT]* ]]; then
        dashyToolsMenu;
    fi

    if [[ "$dashy" == *[uU]* ]]; then
        uninstallApp $app_name;
    fi

    if [[ "$dashy" == *[sS]* ]]; then
        shutdownApp $app_name;
    fi

    if [[ "$dashy" == *[rR]* ]]; then
        if [[ $compose_setup == "default" ]]; then
		    dockerDownUpDefault $app_name;
        elif [[ $compose_setup == "app" ]]; then
            dockerDownUpAdditionalYML $app_name;
        fi
    fi

    if [[ "$dashy" == *[iI]* ]]; then
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
        echo "---- $menu_number. Pulling a default $app_name docker-compose.yml file."
        echo ""

        if [[ $compose_setup == "default" ]]; then
		    setupComposeFileNoApp $app_name;
        elif [[ $compose_setup == "app" ]]; then
            setupComposeFileApp $app_name;
        fi

		((menu_number++))
        echo ""
        echo "---- $menu_number. Setting up conf.yml file."
        echo ""

        dashyUpdateConf;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Updating file permissions before starting."
        echo ""

		fixPermissionsBeforeStart;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		whitelistAndStartApp $app_name;

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
    dashy=n
}