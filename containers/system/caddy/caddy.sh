#!/bin/bash

# Description : Caddy - Reverse Proxy *NOT RECOMMENDED* (c/u/s/r/i):

installCaddy()
{
    app_name=$CFG_CADDY_APP_NAME
    host_name=$CFG_CADDY_HOST_NAME
    domain_number=$CFG_CADDY_DOMAIN_NUMBER
    public=$CFG_CADDY_PUBLIC

    if [[ "$caddy" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

    if [[ "$caddy" == *[uU]* ]]; then
        uninstallApp $app_name;
    fi

    if [[ "$caddy" == *[sS]* ]]; then
        shutdownApp;
    fi

    if [[ "$caddy" == *[rR]* ]]; then
        dockerDownUpDefault;
    fi

    if [[ "$caddy" == *[iI]* ]]; then
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
		
		createTouch $install_dir$app_name/Caddyfile
		
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
    caddy=n
}
