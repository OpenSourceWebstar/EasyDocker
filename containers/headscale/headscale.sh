#!/bin/bash

# Category : system
# Description : Headscale - VPN Networking (c/u/s/r/i):

installHeadscale()
{
    if [[ "$headscale" == *[cCtTuUsSrRiI]* ]]; then
        setupConfigToContainer silent headscale;
        local app_name=$CFG_HEADSCALE_APP_NAME
		setupInstallVariables $app_name;
    fi

    if [[ "$headscale" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

    if [[ "$headscale" == *[uU]* ]]; then
        uninstallApp $app_name;
    fi

    if [[ "$headscale" == *[sS]* ]]; then
        shutdownApp $app_name;
    fi

    if [[ "$headscale" == *[rR]* ]]; then
        dockerDownUp $app_name;
    fi

    if [[ "$headscale" == *[iI]* ]]; then
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

        local result=$(mkdirFolders "loud" $CFG_DOCKER_INSTALL_USER $containers_dir$app_name/config)
        checkSuccess "Create config folder"

		local result=$(copyResource "$app_name" "config.yaml" "config/config.yaml" | sudo -u $sudo_user_name tee -a "$logs_dir/$docker_log_file" 2>&1)
		checkSuccess "Copying config.yaml to config folder."

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

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
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
        echo "    Public : https://$host_setup/"
        echo "    External : http://$public_ip:$usedport1/"
        echo "    Local : http://$ip_setup:$usedport1/"
        echo ""
        echo "    NOTE - The password to login in defined in the yml install file that was installed"
        echo ""
        
		menu_number=0
        sleep 3s
        cd
    fi
    headscale=n
}