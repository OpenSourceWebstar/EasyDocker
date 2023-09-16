#!/bin/bash

# Description : IPInfo - Show IP Address

installIPInfo()
{
    app_name=$CFG_IPINFO_APP_NAME
    host_name=$CFG_IPINFO_HOST_NAME
    domain_number=$CFG_IPINFO_DOMAIN_NUMBER
    public=$CFG_IPINFO_PUBLIC
	port=$CFG_IPINFO_PORT

    if [[ "$ipinfo" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

	if [[ "$ipinfo" == *[uU]* ]]; then
		uninstallApp;
	fi

	if [[ "$ipinfo" == *[sS]* ]]; then
		shutdownApp;
	fi

	if [[ "$ipinfo" == *[rR]* ]]; then
		dockerDownUpDefault;
	fi

    if [[ "$ipinfo" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###           Install $app_name"
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
        echo "---- $menu_number. Updating file permissions before starting."
        echo ""

		fixPermissionsBeforeStart $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		dockerDownUpDefault;

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Opening ports if required"
        echo ""

        openAppPorts;

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
    ipinfo=n
}