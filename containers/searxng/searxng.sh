#!/bin/bash

# Category : privacy
# Description : Searxng - Search Engine (c/u/s/r/i):

installSearXNG()
{
    if [[ -n "$searxng" && "$searxng" =~ [a-mo-zA-Z] ]]; then
        setupConfigToContainer searxng;
		app_name=$CFG_SEARXNG_APP_NAME
	fi

    if [[ "$searxng" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

	if [[ "$searxng" == *[uU]* ]]; then
		uninstallApp $app_name;
	fi

	if [[ "$searxng" == *[sS]* ]]; then
		shutdownApp;
	fi

	if [[ "$searxng" == *[rR]* ]]; then
		setupInstallVariables $app_name;
        if [[ $compose_setup == "default" ]]; then
		    dockerDownUpDefault $app_name;
        elif [[ $compose_setup == "app" ]]; then
            dockerDownUpAdditionalYML $app_name;
        fi
	fi

	if [[ "$searxng" == *[iI]* ]]; then
		echo ""
		echo "##########################################"
		echo "###          Install $app_name"
		echo "##########################################"
		echo ""

		((menu_number++))
		echo ""
		echo "---- $menu_number. Checking custom DNS entry and IP for setup"
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

		# Loop to check for the existence of the file every second
		while [ ! -f "$install_dir$app_name/searxng-data/settings.yml" ]; do
			isNotice "Waiting for the file to appear..."
			read -t 1 # Wait for 1 second
		done

		# Perform the required operation on the file once it exists
		result=$(sudo sed -i "s/simple_style: auto/simple_style: dark/" "$install_dir$app_name/searxng-data/settings.yml")
		checkSuccess "Changing from light mode to dark mode to avoid eye strain installs"

        if [[ $compose_setup == "default" ]]; then
		    dockerDownUpDefault $app_name;
        elif [[ $compose_setup == "app" ]]; then
            dockerDownUpAdditionalYML $app_name;
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
        echo "    You can now navigate to your $app_name service using any of the options below : "
        echo ""
        echo "    Public : https://$host_setup/"
        echo "    External : http://$public_ip:$port/"
        echo "    Local : http://$ip_setup:$port/"
        echo ""
		      
		menu_number=0
        sleep 3s
        cd
	fi
	searxng=n
}