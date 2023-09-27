#!/bin/bash

# Category : system
# Description : Pi-Hole & Unbound - DNS Server *NOT RECOMMENDED* (c/u/s/r/i):

installPihole()
{
    local passedValue="$1"

    if [[ "$passedValue" == "install" ]]; then
        pihole=i
    fi

    if [[ "$pihole" == *[cCtTuUsSrRiI]* ]]; then
        setupConfigToContainer --silent pihole;
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
        if [[ $compose_setup == "default" ]]; then
		    dockerDownUpDefault $app_name;
        elif [[ $compose_setup == "app" ]]; then
            dockerDownUpAdditionalYML $app_name;
        fi
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

		((menu_number++))
        echo ""
        echo "---- $menu_number. Updating file permissions before starting."
        echo ""

		fixPermissionsBeforeStart;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		whitelistAndStartApp $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Editing local variables for DNS server to $app_name"
        echo ""

        if grep -q "$ip_setup" /etc/resolv.conf; then
            checkSuccess "IP Already setup, no need to make changes"
        else
            isQuestion "Do you want to change the default DNS server on the host to use Pi-Hole? (y/n): "
            read -rp "" PHDNS

            if [[ "$PHDNS" =~ ^[yY]$ ]]; then
                # Updating nameserver address in /etc/resolv.conf
                result=$(sudo sed -i "/nameserver/c\#nameserver\nnameserver $ip_setup" /etc/resolv.conf)
                checkSuccess "Updating nameserver in resolv.conf"

                # Updating DNS address in /etc/systemd/resolved.conf
                result=$(sudo sed -i "/DNS=/c\#DNS=\nDNS=$ip_setup" /etc/systemd/resolved.conf)
                checkSuccess "Updating DNS in resolved.conf"

                # Restarting systemd-resolved to apply changes
                result=$(sudo -u $easydockeruser systemctl restart systemd-resolved)
                checkSuccess "Restarting systemd-resolved"
            fi
        fi

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Opening ports if required"
        echo ""

        openAppPorts $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Setting up database records"
        echo ""

		databaseInstallApp $app_name;

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
        echo "    NOTE - The password to login in defined in the yml install file that was installed"
        echo ""
        
		menu_number=0
        sleep 3s
        cd
    fi
    pihole=n
}