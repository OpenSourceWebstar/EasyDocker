#!/bin/bash

# Category : system
# Description : Pi-Hole & Unbound - DNS Server (c/u/s/r/i):

installPihole()
{
    if [[ "$pihole" == *[cCtTuUsSrRiI]* ]]; then
        setupConfigToContainer silent pihole;
        local app_name=$CFG_PIHOLE_APP_NAME
		setupInstallVariables $app_name;
    fi

    if [[ "$pihole" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

    if [[ "$pihole" == *[uU]* ]]; then
        uninstallApp $app_name;
    fi

    if [[ "$pihole" == *[sS]* ]]; then
        shutdownApp $app_name;
    fi

    if [[ "$pihole" == *[rR]* ]]; then
        dockerDownUp $app_name;
    fi

    if [[ "$pihole" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###           Install $app_name"
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
        echo "---- $menu_number. Setting up database records"
        echo ""

		databaseInstallApp $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. You can find $app_name files at $containers_dir$app_name"
        echo ""
        echo "    You can now navigate to your $app_name service using any of the options below : "
        echo ""
        echo "    NOTE - The password to login in defined in the yml install file that was installed"
        echo ""

        menuShowFinalMessages $app_name;
        
		menu_number=0
        sleep 3s
        cd
    fi
    pihole=n
}