#!/bin/bash

# Category : user
# Description : GitLab - DevOps Platform *UNFINISHED* (c/u/s/r/i):

installGitlab()
{
    passedValue="$1"

    if [[ "$passedValue" == "install" ]]; then
        gitlab=i
    fi

    if [[ ! -n "$gitlab" || "$gitlab" != "n" ]]; then
        setupConfigToContainer gitlab;
        app_name=$CFG_GITLAB_APP_NAME
    fi
    
    if [[ "$gitlab" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

	if [[ "$gitlab" == *[uU]* ]]; then
		uninstallApp $app_name;
	fi

	if [[ "$gitlab" == *[sS]* ]]; then
		shutdownApp;
	fi

    if [[ "$gitlab" == *[rR]* ]]; then
		setupInstallVariables $app_name;
        if [[ $compose_setup == "default" ]]; then
		    dockerDownUpDefault $app_name;
        elif [[ $compose_setup == "app" ]]; then
            dockerDownUpAdditionalYML $app_name;
        fi
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

		setupInstallVariables $app_name;

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
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		whitelistAndStartApp $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Updating file permissions before starting."
        echo ""

		fixPermissionsBeforeStart;

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Opening ports if required"
        echo ""

        openAppPorts $app_name;

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