#!/bin/bash

# Category : system
# Description : Wireguard Easy - VPN Server (c/u/s/r/i):

installWireguard()
{
    local passedValue="$1"

    if [[ "$passedValue" == "install" ]]; then
        wireguard=i
    fi

    if [[ "$wireguard" == *[cCtTuUsSrRiI]* ]]; then
        setupConfigToContainer --silent wireguard;
        local app_name=$CFG_WIREGUARD_APP_NAME
		setupInstallVariables $app_name;
    fi
    
    if [[ "$wireguard" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

    if [[ "$wireguard" == *[uU]* ]]; then
        uninstallApp $app_name;
    fi

    if [[ "$wireguard" == *[sS]* ]]; then
        shutdownApp $app_name;
    fi

    if [[ "$wireguard" == *[rR]* ]]; then
        if [[ $compose_setup == "default" ]]; then
		    dockerDownUpDefault $app_name;
        elif [[ $compose_setup == "app" ]]; then
            dockerDownUpAdditionalYML $app_name;
        fi
    fi

    if [[ "$wireguard" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###          Install $app_name"
        echo "##########################################"
        echo ""

		((menu_number++))
        echo ""
        echo "---- $menu_number. Setting up install folder and config file for $app_name."
        echo ""

        setupConfigToContainer "" $app_name install;
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

		((menu_number++))
		echo ""
        echo "---- $menu_number. Enabling IP forwarding"
		echo ""

        local result=$(sudo sed -i "s/#net.ipv4.ip_forward/net.ipv4.ip_forward/g" /etc/sysctl.d/99-sysctl.conf)
		checkSuccess "Enabling IPv4 IP Forwarding in the 99-sysctl.conf file (Kernel)"

        local result=$(sudo sysctl -p)
		checkSuccess "Apply changes made to the System's Kernel "

		((menu_number++))
        echo ""
        echo "---- $menu_number. Updating file permissions before starting."
        echo ""

		fixPermissionsBeforeStart $app_name;

		((menu_number++))
		echo ""
        echo "---- $menu_number. Running the docker-compose.yml to Install $app_name"
        echo ""

		whitelistAndStartApp $app_name;

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Opening ports if required"
        echo ""

        openAppPorts $app_name;

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
    wireguard=n
}
