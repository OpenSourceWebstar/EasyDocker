#!/bin/bash

# Description : Watchtower - Docker Updater

installWatchtower()
{
    app_name=$CFG_WATCHTOWER_APP_NAME

    if [[ "$watchtower" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

    if [[ "$watchtower" == *[uU]* ]]; then
        uninstallApp;
    fi

    if [[ "$watchtower" == *[sS]* ]]; then
        shutdownApp;
    fi

    if [[ "$watchtower" == *[rR]* ]]; then
        dockerDownUpDefault;
    fi

    if [[ "$watchtower" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###           Install $app_name"
        echo "##########################################"
        echo ""

		((menu_number++))
        echo ""
        echo "---- $menu_number. Pulling a default $app_name docker-compose.yml file."
        echo ""

		setupComposeFileNoApp;
		editComposeFileDefault;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Updating file permissions before starting."
        echo ""

		fixPermissionsBeforeStart;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		dockerDownUpDefault;

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Opening ports if required"
        echo ""

        openAppPorts;

		((menu_number++))
		echo ""
        echo "---- $menu_number. Adding $app_name to the Apps Database table."
        echo ""

		databaseInstallApp;

		((menu_number++))
        echo ""
        echo "---- $menu_number. You can find $app_name files at $install_path$app_name"
        echo ""
    
		menu_number=0
        sleep 3s
        cd
    fi
    watchtower=n
}