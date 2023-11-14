#!/bin/bash

# Category : system
# Description : Grafana - Metrics Visualizer (c/u/s/r/i):

installGrafana()
{
    if [[ "$grafana" == *[cCtTuUsSrRiI]* ]]; then
        setupConfigToContainer silent grafana;
        local app_name=$CFG_GRAFANA_APP_NAME
		setupInstallVariables $app_name;
    fi

    if [[ "$grafana" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

	if [[ "$grafana" == *[uU]* ]]; then
		uninstallApp $app_name;
	fi

	if [[ "$grafana" == *[sS]* ]]; then
		shutdownApp $app_name;
	fi

	if [[ "$grafana" == *[rR]* ]]; then
        dockerDownUp $app_name;
	fi

    if [[ "$grafana" == *[iI]* ]]; then
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

		whitelistAndStartApp $app_name install;

        # Grafana
        if [ -d "${containers_dir}grafana/grafana_storage" ]; then
            local result=$(sudo chmod -R 777 "${containers_dir}grafana/grafana_storage")
            checkSuccess "Set permissions to grafana_storage folder."
        fi

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
        echo "    Public : https://$host_setup/"
        echo "    External : http://$public_ip:$usedport1/"
        echo "    Local : http://$ip_setup:$usedport1/"
        echo ""
		      
		menu_number=0
        sleep 3s
        cd
    fi
    grafana=n
}