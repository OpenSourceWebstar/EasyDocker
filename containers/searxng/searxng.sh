#!/bin/bash

# Category : privacy
# Description : Searxng - Search Engine (c/u/s/r/i):

installSearxng()
{
    if [[ "$searxng" == *[cCtTuUsSrRiI]* ]]; then
        setupConfigToContainer silent searxng;
		local app_name=$CFG_SEARXNG_APP_NAME
		setupInstallVariables $app_name;
	fi

    if [[ "$searxng" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

	if [[ "$searxng" == *[uU]* ]]; then
		uninstallApp $app_name;
	fi

	if [[ "$searxng" == *[sS]* ]]; then
		shutdownApp $app_name;
	fi

	if [[ "$searxng" == *[rR]* ]]; then
        dockerDownUp $app_name;
	fi

	if [[ "$searxng" == *[iI]* ]]; then
		echo ""
		echo "##########################################"
		echo "###          Install $app_name"
		echo "##########################################"
		echo ""

		((menu_number++))
        echo ""
        echo "---- $menu_number. Setting up install folder and config file for $app_name."
        echo ""

        setupConfigToContainer "loud" "$app_name" "install";
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

        setupComposeFile $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Updating file permissions before starting."
        echo ""

		fixPermissionsBeforeStart $app_name;

		((menu_number++))
        echo ""
		echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
		echo ""

		whitelistAndStartApp $app_name install;

        searxng_timeout=10
        searxng_counter=0
        # Loop to check for the existence of the file every second
        while [ ! -f "$containers_dir$app_name/searxng-data/settings.yml" ]; do
            if [ "$searxng_counter" -ge "$searxng_timeout" ]; then
                isNotice "File not found after 10 seconds. Exiting..."
                break
            fi

            isNotice "Waiting for the file to appear..."
            read -t 1 # Wait for 1 second

            # Increment the counter
            searxng_counter=$((searxng_counter + 1))
        done

        # Check if the file was found or if we timed out
        if [ -f "$containers_dir$app_name/searxng-data/settings.yml" ]; then
            # Perform the required operation on the file once it exists
            local result=$(sudo sed -i "s/simple_style: auto/simple_style: $CFG_SEARXNG_THEME/" "$containers_dir$app_name/searxng-data/settings.yml")
            checkSuccess "Changing from light mode to dark mode to avoid eye strain installs"

            dockerDownUp $app_name;
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
        echo "    You can now navigate to your $app_name service using any of the options below : "
        echo ""
        echo "    Public : https://$host_setup/"
        echo "    External : http://$public_ip:$usedport1/"
        echo "    Local : http://$ip_setup:$usedport1/"
        echo ""
		      
		menu_number=0
        sleep 3s
        cd
	fi
	searxng=n
}