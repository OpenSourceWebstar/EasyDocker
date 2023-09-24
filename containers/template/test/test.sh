#!/bin/bash

# Description : Test - It just works! (c/u/s/r/i):

installTest()
{
    if [[ "$test" =~ [a-zA-Z] ]]; then
        app_name=$CFG_TEST_APP_NAME
    fi

    if [[ "$test" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

    if [[ "$test" == *[uU]* ]]; then
        uninstallApp $app_name;
    fi

    if [[ "$test" == *[sS]* ]]; then
        shutdownApp;
    fi

    if [[ "$test" == *[rR]* ]]; then
        dockerDownUpDefault $app_name;
    fi

    if [[ "$test" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###          Install $app_name"
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

		setupComposeFileNoApp;
		whitelistApp $app_name false;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Updating file permissions before starting."
        echo ""

		fixPermissionsBeforeStart;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		dockerDownUpDefault $app_name;

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
    test=n
}
