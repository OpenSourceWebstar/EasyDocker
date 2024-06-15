#!/bin/bash

# Category : privacy
# Description : Baikal - CardDAV server (c/u/s/r/i):

installBaikal()
{
    if [[ "$baikal" == *[cCtTuUsSrRiI]* ]]; then
        dockerConfigSetupToContainer silent baikal;
        local app_name=$CFG_BAIKAL_APP_NAME
		setupInstallVariables $app_name;
    fi

    if [[ "$baikal" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

    if [[ "$baikal" == *[uU]* ]]; then
        dockerUninstallApp $app_name;
    fi

    if [[ "$baikal" == *[sS]* ]]; then
        dockerComposeDown $app_name;
    fi

    if [[ "$baikal" == *[rR]* ]]; then
        dockerComposeRestart $app_name;
    fi

    if [[ "$baikal" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###          Install $app_name"
        echo "##########################################"
        echo ""

		((menu_number++))
        echo ""
        echo "---- $menu_number. Setting up install folder and config file for $app_name."
        echo ""

        dockerConfigSetupToContainer "loud" "$app_name" "install";
        isSuccessful "Install folders and Config files have been setup for $app_name."

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Checking & Opening ports if required"
        echo ""

        portsCheckApp $app_name install;
        if [[ $disallow_used_port == "true" ]]; then
            isError "A used port conflict has occured, setup is cancelling..."
            disallow_used_port=""
            return
        else
            isSuccessful "No used port conflicts found, setup is continuing..."
        fi
        if [[ $disallow_open_port == "true" ]]; then
            isError "An open port conflict has occured, setup is cancelling..."
            disallow_open_port=""
            return
        else
            isSuccessful "No open port conflicts found, setup is continuing..."
        fi
        
		((menu_number++))
        echo ""
        echo "---- $menu_number. Setting up the $app_name docker-compose.yml file."
        echo ""

        dockerComposeSetupFile $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Updating file permissions before starting."
        echo ""

		fixPermissionsBeforeStart $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		dockerComposeUpdateAndStartApp $app_name install;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Adjusting $app_name Nginx docker system files for port changes."
        echo ""

        dockerCommandRun "docker exec -it $app_name /bin/bash -c 'sed -i "/^ *listen/s/[0-9]\\+/$usedport1/g" /etc/nginx/conf.d/default.conf'"
		dockerComposeRestart $app_name;

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Running Application specific updates (if required)"
        echo ""

        appUpdateSpecifics $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running Headscale setup (if required)"
        echo ""

		setupHeadscale $app_name;

		((menu_number++))
		echo ""
        echo "---- $menu_number. Adding $app_name to the Apps Database table."
        echo ""

		databaseInstallApp $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. You can find $app_name files at $containers_dir$app_name"
        echo ""
        echo "    You can now navigate to your $app_name service using any of the options below : "
        echo ""
        
        menuShowFinalMessages $app_name;

		menu_number=0
        sleep 3s
        cd
    fi
    baikal=n
}
