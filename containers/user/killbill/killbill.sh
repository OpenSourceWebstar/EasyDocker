#!/bin/bash

# Description : Killbill - Payment Processing

installKillbill()
{
    app_name=$CFG_KILLBILL_APP_NAME
    host_name=$CFG_KILLBILL_HOST_NAME
    domain_number=$CFG_KILLBILL_DOMAIN_NUMBER
    public=$CFG_KILLBILL_PUBLIC
	port=$CFG_KILLBILL_PORT
    
    if [[ "$killbill" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

	if [[ "$killbill" == *[uU]* ]]; then
		uninstallApp;
	fi

	if [[ "$killbill" == *[sS]* ]]; then
		shutdownApp;
	fi

    if [[ "$killbill" == *[rR]* ]]; then
        dockerDownUpDefault;
    fi

    if [[ "$killbill" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###      Install $app_name"
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
        echo "---- $menu_number. You can find $app_name files at $install_dir$app_name"
        echo ""
        echo "    You can now navigate to your new service using one of the options below : "
        echo ""
        echo "    Public : https://$host_setup/"
        echo "    External : http://$public_ip:$port/"
        echo "    Local : http://$ip_setup:$port/"
        echo ""
		   
		menu_number=0
        sleep 3s
        cd
	fi
	killbill=n
}