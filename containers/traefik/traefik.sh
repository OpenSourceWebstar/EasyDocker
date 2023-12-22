#!/bin/bash

# Category : system
# Description : Traefik - Reverse Proxy (c/u/s/r/i):

installTraefik()
{
    if [[ "$traefik" == *[cCtTuUsSrRiI]* ]]; then
        setupConfigToContainer silent traefik;
        local app_name=$CFG_TRAEFIK_APP_NAME
		setupInstallVariables $app_name;
    fi

    if [[ "$traefik" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

    if [[ "$traefik" == *[uU]* ]]; then
        uninstallApp $app_name;
    fi

    if [[ "$traefik" == *[sS]* ]]; then
        shutdownApp $app_name;
    fi

    if [[ "$traefik" == *[rR]* ]]; then   
        dockerDownUp $app_name;
    fi

    if [[ "$traefik" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###         Install $app_name"
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
		
        # Create necessary directories and set permissions
        local result=$(mkdirFolders "loud" $CFG_DOCKER_INSTALL_USER "$containers_dir$app_name/etc" "$containers_dir$app_name/etc/certs" "$containers_dir$app_name/etc/dynamic" "$containers_dir$app_name/etc/dynamic/middlewears")
        checkSuccess "Created etc and certs & dynamic Directories"

        # Create and secure the acme.json file
        local result=$(createTouch "$containers_dir$app_name/etc/certs/acme.json" $CFG_DOCKER_INSTALL_USER)
        checkSuccess "Created acme.json file for $app_name"

        # Static traefik.yml File
        # Copy the Traefik configuration file and customize it
        local result=$(copyResource "$app_name" "traefik.yml" "etc")
        checkSuccess "Copy Traefik configuration file for $app_name"

        # Setup Debug Level
        local result=$(sudo sed -i "s|DEBUGLEVEL|$CFG_TRAEFIK_LOGGING|g" "$containers_dir$app_name/etc/traefik.yml")
        checkSuccess "Configured Traefik debug level with: $CFG_TRAEFIK_LOGGING for $app_name"

        setupFileWithConfigData $app_name "traefik.yml" "etc";

        # Dynamic config.yml File
        # Copy the Traefik configuration file and customize it
        local result=$(copyResource "$app_name" "config.yml" "etc/dynamic")
        checkSuccess "Copy Traefik Dynamic config.yml configuration file for $app_name"

        # Setup Error 404 Website
        local result=$(sudo sed -i "s|ERRORWEBSITE|$CFG_TRAEFIK_404_SITE|g" "$containers_dir$app_name/etc/dynamic/config.yml")
        checkSuccess "Configured Traefik error website with URL: $CFG_TRAEFIK_404_SITE for $app_name"

        setupFileWithConfigData $app_name "config.yml" "etc/dynamic";

        # Dynamic whitelist.yml File
        local result=$(copyResource "$app_name" "whitelist.yml" "etc/dynamic")
        checkSuccess "Copy Traefik Dynamic whitelist.yml configuration file for $app_name"

        # Middlewears
        # Dynamic protectionauth.yml File
        local result=$(copyResource "$app_name" "protectionauth.yml" "etc/dynamic/middlewears")
        checkSuccess "Copy Traefik Dynamic protectionauth.yml configuration file for $app_name"

        dockerUpdateTraefikWhitelist;

        # Dynamic tls.yml File
        local result=$(copyResource "$app_name" "tls.yml" "etc/dynamic")
        checkSuccess "Copy Traefik Dynamic tls.yml configuration file for $app_name"

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		dockerUpdateAndStartApp $app_name install;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Updating file permissions before starting."
        echo ""

		fixPermissionsBeforeStart $app_name;

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
        
        menuShowFinalMessages $app_name;

		menu_number=0
        sleep 3s
        cd
    fi
    traefik=n
}