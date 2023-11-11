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
        local result=$(mkdirFolders "loud" $CFG_DOCKER_INSTALL_USER "$containers_dir$app_name/etc" "$containers_dir$app_name/etc/certs")
        checkSuccess "Create /etc/ and /etc/certs Directories"

        # Create and secure the acme.json file
        local result=$(createTouch "$containers_dir$app_name/etc/certs/acme.json")
        checkSuccess "Created acme.json file for $app_name"

        # Copy the Traefik configuration file and customize it
        local result=$(copyResource "$app_name" "traefik.yml" "/etc/traefik.yml")
        checkSuccess "Copy Traefik configuration file for $app_name"

        # Setup Error 404 Website
        local result=$(sudo sed -i "s|ERRORWEBSITE|$CFG_TRAEFIK_404_SITE|g" "$containers_dir$app_name/etc/traefik.yml")
        checkSuccess "Configured Traefik error website with URL: $CFG_TRAEFIK_404_SITE for $app_name"

        # Setup Debug Level
        local result=$(sudo sed -i "s|DEBUGLEVEL|$CFG_TRAEFIK_LOGGING|g" "$containers_dir$app_name/etc/traefik.yml")
        checkSuccess "Configured Traefik debug level with: $CFG_TRAEFIK_LOGGING for $app_name"

        # Setup BasicAuth credentials
        local password_hash=$(htpasswd -Bbn "$CFG_TRAEFIK_DASHBOARD_USER" "$CFG_TRAEFIK_DASHBOARD_PASS")
        local result=$(sudo awk -v user="$CFG_TRAEFIK_DASHBOARD_USER" -v password_hash="$password_hash" '/^\s*traefikAuth:/ {n=NR} n && NR==n+3 {$0="          - \"" password_hash "\""} 1' "$containers_dir/$app_name/etc/traefik.yml" | sudo tee "$containers_dir/$app_name/etc/temp_traefik.yml" > /dev/null)
        checkSuccess "Configured traefik.yml with BasicAuth credentials for user : $CFG_TRAEFIK_DASHBOARD_USER"
        local result=$(sudo mv "$containers_dir/$app_name/etc/temp_traefik.yml" "$containers_dir/$app_name/etc/traefik.yml")
        checkSuccess "Using temp traefik.yml as the new live file after changes."

        setupFileWithConfigData $app_name "traefik.yml" "etc";

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
        echo "---- $menu_number. Restarting $app_name after firewall changes"
        echo ""

        dockerDownUp $app_name;

		((menu_number++))
		echo ""
        echo "---- $menu_number. Adding $app_name to the Apps Database table."
        echo ""

		databaseInstallApp $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running Headscale setup (if required)"
        echo ""

		setupHeadscale $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. You can find $app_name files at $containers_dir$app_name"
        echo ""
        echo "    You can now navigate to your $app_name service using any of the options below : "
        echo ""
        echo "    Your username is : $CFG_TRAEFIK_DASHBOARD_USER"
        echo "    Your password is : $CFG_TRAEFIK_DASHBOARD_PASS"
        echo ""
        echo "    Public : https://$host_setup/"
        echo "    External : http://$public_ip:$usedport1/"
        echo "    Local : http://$ip_setup:$usedport1/"
        echo ""

		menu_number=0
        sleep 3s
        cd
    fi
    traefik=n
}