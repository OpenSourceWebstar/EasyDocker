#!/bin/bash

# Description : Wireguard Easy - VPN Server

installWireguard()
{
    app_name=$CFG_WIREGUARD_APP_NAME
    host_name=$CFG_WIREGUARD_HOST_NAME
    domain_number=$CFG_WIREGUARD_DOMAIN_NUMBER
    public=$CFG_WIREGUARD_PUBLIC
	port=$CFG_WIREGUARD_PORT
    
    if [[ "$wireguard" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

    if [[ "$wireguard" == *[uU]* ]]; then
        uninstallApp;
    fi

    if [[ "$wireguard" == *[sS]* ]]; then
        shutdownApp;
    fi

    if [[ "$wireguard" == *[rR]* ]]; then
        dockerDownUpDefault;
    fi

    if [[ "$wireguard" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###          Install $app_name"
        echo "##########################################"
        echo ""

		((menu_number++))
		echo ""
		echo "---- $menu_number. Checking custom DNS entry and IP for setup"
		echo ""

		setupIPsAndHostnames;

		((menu_number++))
		echo ""
        echo "---- $menu_number. Pulling a default $app_name docker-compose.yml file."
		echo ""

		setupComposeFileNoApp;
		editComposeFileDefault;

		((menu_number++))
		echo ""
        echo "---- $menu_number. Enabling IP forwarding"
		echo ""

        result=$(sudo sed -i "s/#net.ipv4.ip_forward/net.ipv4.ip_forward/g" /etc/sysctl.d/99-sysctl.conf)
		checkSuccess "Enabling IPv4 IP Forwarding in the 99-sysctl.conf file (Kernel)"

        result=$(sudo sysctl -p)
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

		dockerDownUpDefault;

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Opening ports if required"
        echo ""

        openAppPorts;

		((menu_number++))
		echo ""
        echo "---- $menu_number. Restarting $app_name after firewall changes"
        echo ""

		dockerDownUpDefault;

		((menu_number++))
		echo ""
        echo "---- $menu_number. Adding $app_name to the Apps Database table."
        echo ""

		databaseInstallApp;

		((menu_number++))
        echo ""
        echo "---- $menu_number. You can find $app_name files at $install_path$app_name"
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
