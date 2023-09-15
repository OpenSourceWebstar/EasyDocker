#!/bin/bash

# Description : Portainer - Docker Management

installPortainer()
{
    app_name=$CFG_PORTAINER_APP_NAME
    host_name=$CFG_PORTAINER_HOST_NAME
    domain_number=$CFG_PORTAINER_DOMAIN_NUMBER
    public=$CFG_PORTAINER_PUBLIC
	port=$CFG_PORTAINER_PORT

    if [[ "$portainer" == *[uU]* ]]; then
        uninstallApp;
    fi

    if [[ "$portainer" == *[sS]* ]]; then
        shutdownApp;
    fi

    if [[ "$portainer" == *[rR]* ]]; then
        dockerDownUpDefault;
    fi

    if [[ "$portainer" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###      Installing $app_name"
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
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		dockerDownUpDefault;
		dockerDownUpDefault

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
    portainer=n
}
