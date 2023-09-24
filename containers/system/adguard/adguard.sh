#!/bin/bash

# Description : Adguard & Unbound - DNS Server (c/u/s/r/i):

installAdguard()
{
    setupInstallVariables $app_name;

    if [[ "$adguard" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

    if [[ "$adguard" == *[uU]* ]]; then
        uninstallApp $app_name;
    fi

    if [[ "$adguard" == *[sS]* ]]; then
        shutdownApp;
    fi

    if [[ "$adguard" == *[rR]* ]]; then
        dockerDownUpDefault $app_name;
    fi

    if [[ "$adguard" == *[iI]* ]]; then
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

		setupComposeFileNoApp;
		whitelistApp $app_name false;

		result=$(copyResource "$app_name" "unbound.conf" "unbound.conf" | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" 2>&1)
		checkSuccess "Copying unbound.conf to containers folder."

		((menu_number++))
        echo ""
        echo "---- $menu_number. Updating file permissions before starting."
        echo ""

		fixPermissionsBeforeStart;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		dockerDownUpDefault $app_name;

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
        echo "    You can now navigate to your $app_name service using any of the options below : "
		echo "    NOTICE : Setup is needed in order to get Adguard online"
        echo ""
        echo "    Public : https://$host_setup/"
        echo "    External : http://$public_ip:$port/"
        echo "    Local : http://$ip_setup:$port/"
        echo ""

		menu_number=0
        sleep 3s
        cd
    fi
    adguard=n
}