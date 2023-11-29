#!/bin/bash

# Category : privacy
# Description : Trilium - Note Manager (c/u/s/r/i):

installTrilium()
{
    if [[ "$trilium" == *[cCtTuUsSrRiI]* ]]; then
        setupConfigToContainer silent trilium;
        local app_name=$CFG_TRILIUM_APP_NAME
		setupInstallVariables $app_name;
    fi

    if [[ "$trilium" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

    if [[ "$trilium" == *[uU]* ]]; then
        uninstallApp $app_name;
    fi

    if [[ "$trilium" == *[sS]* ]]; then
        shutdownApp $app_name;
    fi

    if [[ "$trilium" == *[rR]* ]]; then
        dockerDownUp $app_name;
    fi

    if [[ "$trilium" == *[iI]* ]]; then
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

		dockerUpdateAndStartApp $app_name install;

		((menu_number++))
		echo ""
        echo "---- $menu_number. Updating defaul port and restarting $app_name"
        echo ""

        local trilium_timeout=10
        local trilium_counter=0
        # Loop to check for the existence of the file every second
        while [ ! -f "$containers_dir$app_name/trilium-data/config.ini" ]; do
            if [ "$trilium_counter" -ge "$trilium_timeout" ]; then
                isNotice "File not found after 10 seconds. Exiting..."
                break
            fi

            isNotice "Waiting for the file to appear..."
            read -t 1 # Wait for 1 second

            # Increment the counter
            local trilium_counter=$((trilium_counter + 1))
        done

        result=$(sudo sed -i "s|port=8080|port=$usedport1|g" "$containers_dir$app_name/trilium-data/config.ini")
        checkSuccess "Configured $app_name from default 8080 to $usedport1"

        dockerDownUp $app_name;

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Running Application specific updates (if required)"
        echo ""

        updateApplicationSpecifics $app_name;

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
        echo "    You can now navigate to your $app_name service using any of the options below : "
        echo ""
        
        menuShowFinalMessages;
		     
		menu_number=0
        sleep 3s
        cd
    fi
    trilium=n
}