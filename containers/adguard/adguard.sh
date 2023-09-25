#!/bin/bash

# Category : system
# Description : Adguard & Unbound - DNS Server (c/u/s/r/i):

installAdguard()
{
    passedValue="$1"

    if [[ "$passedValue" == "install" ]]; then
        adguard=i
    fi

    if [[ "$adguard" == *[cCtTuUsSrRiI]* ]]; then
        setupConfigToContainer adguard;
        app_name=$CFG_ADGUARD_APP_NAME
    	setupInstallVariables $app_name;
    fi

    if [[ "$adguard" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

    if [[ "$adguard" == *[uU]* ]]; then
        uninstallApp $app_name;
    fi

    if [[ "$adguard" == *[sS]* ]]; then
        shutdownApp $app_name;
    fi

    if [[ "$adguard" == *[rR]* ]]; then
        if [[ $compose_setup == "default" ]]; then
		    dockerDownUpDefault $app_name;
        elif [[ $compose_setup == "app" ]]; then
            dockerDownUpAdditionalYML $app_name;
        fi
    fi

    if [[ "$adguard" == *[iI]* ]]; then
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

		((menu_number++))
        echo ""
        echo "---- $menu_number. Pulling a default $app_name docker-compose.yml file."
        echo ""

        if [[ $compose_setup == "default" ]]; then
		    setupComposeFileNoApp $app_name;
        elif [[ $compose_setup == "app" ]]; then
            setupComposeFileApp $app_name;
        fi

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