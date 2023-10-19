#!/bin/bash

# Category : system
# Description : Traefik - Reverse Proxy *RECOMMENDED* (c/u/s/r/i):

installTraefik()
{
    local passedValue="$1"

    if [[ "$passedValue" == "install" ]]; then
        traefik=i
    fi

    if [[ "$traefik" == *[cCtTuUsSrRiI]* ]]; then
        setupConfigToContainer --silent traefik;
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
        if [[ $compose_setup == "default" ]]; then
		    dockerDownUpDefault $app_name;
        elif [[ $compose_setup == "app" ]]; then
            dockerDownUpAdditionalYML $app_name;
        fi
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

        setupConfigToContainer $app_name install;
        isSuccessful "Install folders and Config files have been setup for $app_name."

		((menu_number++))
        echo ""
        echo "---- $menu_number. Pulling a default $app_name docker-compose.yml file."
        echo ""

        if [[ $compose_setup == "default" ]]; then
		    setupComposeFileNoApp $app_name;
        elif [[ $compose_setup == "app" ]]; then
            setupComposeFileApp $app_name;
        fi
		
        # Create necessary directories and set permissions
        local result=$(mkdirFolders "$containers_dir$app_name/etc" "$containers_dir$app_name/etc/certs")
        checkSuccess "Create /etc/ and /etc/certs Directories"

        # Create and secure the acme.json file
        local result=$(createTouch "$containers_dir$app_name/etc/certs/acme.json")
        checkSuccess "Created acme.json file for $app_name"

        # Copy the Traefik configuration file and customize it
        local result=$(copyResource "$app_name" "traefik.yml" "/etc/traefik.yml")
        checkSuccess "Copy Traefik configuration file for $app_name"

        # Replace the placeholder email with the actual email for Let's Encrypt SSL certificates
        local result=$(sudo sed -i "s/your-email@example.com/$CFG_EMAIL/g" "$containers_dir$app_name/etc/traefik.yml")
        checkSuccess "Configured Traefik with email: $CFG_EMAIL for $app_name"

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		whitelistAndStartApp $app_name install;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Updating file permissions before starting."
        echo ""

		fixPermissionsBeforeStart $app_name;

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Checking & Opening ports if required"
        echo ""

        checkAppPorts $app_name;

		((menu_number++))
		echo ""
        echo "---- $menu_number. Restarting $app_name after firewall changes"
        echo ""

        if [[ $compose_setup == "default" ]]; then
		    dockerDownUpDefault $app_name;
        elif [[ $compose_setup == "app" ]]; then
            dockerDownUpAdditionalYML $app_name;
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
        echo "    External : http://$public_ip:$port/"
        echo "    Local : http://$ip_setup:$port/"
        echo ""

		menu_number=0
        sleep 3s
        cd
    fi
    traefik=n
}