#!/bin/bash

# Description : Adguard & Unbound - DNS Server

installAdguard()
{
    app_name=$CFG_ADGUARD_APP_NAME
    host_name=$CFG_ADGUARD_HOST_NAME
    domain_number=$CFG_ADGUARD_DOMAIN_NUMBER
    public=$CFG_ADGUARD_PUBLIC
	port=$CFG_ADGUARD_PORT

    if [[ "$adguard" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

    if [[ "$adguard" == *[uU]* ]]; then
        uninstallApp;
    fi

    if [[ "$adguard" == *[sS]* ]]; then
        shutdownApp;
    fi

    if [[ "$adguard" == *[rR]* ]]; then
        dockerDownUpDefault;
    fi

    if [[ "$adguard" == *[iI]* ]]; then
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

		result=$(copyResource "$app_name" "/unbound/unbound.conf" "unbound.conf" | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" 2>&1)
		checkSuccess "Copying unbound.conf to containers folder."

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
		echo "    NOTICE : Setup is needed in order to get Adguard online"
        echo ""
        echo "    Public : https://$host_setup/"
        echo "    External : http://$public_ip:$port/"
        echo "    Local : http://$ip_setup:$port/"
        echo ""

		menu_number=0
        sleep 3s
        cd
    fi
    adguard=n
}