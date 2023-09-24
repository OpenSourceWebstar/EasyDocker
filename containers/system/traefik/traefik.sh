#!/bin/bash

# Description : Traefik - Reverse Proxy *RECOMMENDED* (c/u/s/r/i):

installTraefik()
{
    app_name=$CFG_TRAEFIK_APP_NAME
    setupInstallVariables $app_name;

    if [[ "$traefik" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

    if [[ "$traefik" == *[uU]* ]]; then
        uninstallApp $app_name;
    fi

    if [[ "$traefik" == *[sS]* ]]; then
        shutdownApp;
    fi

    if [[ "$traefik" == *[rR]* ]]; then      
        dockerDownUpDefault $app_name;
    fi

    if [[ "$traefik" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###         Install $app_name"
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
		
        # Create necessary directories and set permissions
        result=$(mkdirFolders "$install_dir$app_name/etc" "$install_dir$app_name/etc/certs")
        checkSuccess "Create /etc/ and /etc/certs Directories"

        # Create and secure the acme.json file
        result=$(createTouch "$install_dir$app_name/etc/certs/acme.json")
        checkSuccess "Created acme.json file for $app_name"

        # Copy the Traefik configuration file and customize it
        result=$(copyResource "$app_name" "traefik.yml" "/etc/traefik.yml")
        checkSuccess "Copy Traefik configuration file for $app_name"

        # Replace the placeholder email with the actual email for Let's Encrypt SSL certificates
        result=$(sudo sed -i "s/your-email@example.com/$CFG_EMAIL/g" "$install_dir$app_name/etc/traefik.yml")
        checkSuccess "Configured Traefik with email: $CFG_EMAIL for $app_name"

		whitelistApp $app_name false;

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
        echo "---- $menu_number. Restarting $app_name after firewall changes"
        echo ""

		dockerDownUpDefault $app_name;

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
    traefik=n
}