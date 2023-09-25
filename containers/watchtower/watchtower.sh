#!/bin/bash

# Category : system
# Description : Watchtower - Docker Updater (c/u/s/r/i):

installWatchtower()
{
    passedValue="$1"

    if [[ "$passedValue" == "install" ]]; then
        watchtower=i
    fi

    if [[ -n "$watchtower" && "$watchtower" != "n" ]]; then
        setupConfigToContainer watchtower;
        app_name=$CFG_WATCHTOWER_APP_NAME
    fi

    if [[ "$watchtower" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

    if [[ "$watchtower" == *[uU]* ]]; then
        uninstallApp $app_name;
    fi

    if [[ "$watchtower" == *[sS]* ]]; then
        shutdownApp;
    fi

    if [[ "$watchtower" == *[rR]* ]]; then
		setupInstallVariables $app_name;
        if [[ $compose_setup == "default" ]]; then
		    dockerDownUpDefault $app_name;
        elif [[ $compose_setup == "app" ]]; then
            dockerDownUpAdditionalYML $app_name;
        fi
    fi

    if [[ "$watchtower" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###           Install $app_name"
        echo "##########################################"
        echo ""

		((menu_number++))
        echo ""
		echo "---- $menu_number. Setting up install variables."
		echo ""

        setupInstallVariables $app_name;

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
    
		menu_number=0
        sleep 3s
        cd
    fi
    watchtower=n
}