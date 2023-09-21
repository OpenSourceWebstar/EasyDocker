#!/bin/bash

# Description : GitLab - DevOps Platform *UNFINISHED* (c/u/s/r/i):

installGitLab()
{
    app_name=$CFG_GITLAB_APP_NAME
    host_name=$CFG_GITLAB_HOST_NAME
    domain_number=$CFG_GITLAB_DOMAIN_NUMBER
    public=$CFG_GITLAB_PUBLIC
	port=$CFG_GITLAB_PORT
	port_2=$CFG_GITLAB_PORT_2
    
    if [[ "$gitlab" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

	if [[ "$gitlab" == *[uU]* ]]; then
		uninstallApp;
	fi

	if [[ "$gitlab" == *[sS]* ]]; then
		shutdownApp;
	fi

    if [[ "$gitlab" == *[rR]* ]]; then
        dockerDownUpDefault;
    fi

    if [[ "$gitlab" == *[iI]* ]]; then
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
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		dockerDownUpDefault;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Updating file permissions before starting."
        echo ""

		fixPermissionsBeforeStart $app_name;

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
        echo "    You can now navigate to your $app_name service using one of the options below : "
        echo ""
        echo "    Public : https://$host_setup/"
        echo "    External : http://$public_ip:$port/"
        echo "    Local : http://$ip_setup:$port/"
        echo ""
		      
		menu_number=0
        sleep 3s
        cd
	fi
	gitlab=n
}