#!/bin/bash

# Category : privacy
# Description : Piped - Alternative YouTube Frontend (c/u/s/r/i/t):

installPiped()
{
    if [[ "$piped" == *[cCtTuUsSrRiI]* ]]; then
        dockerConfigSetupToContainer silent piped;
        local app_name=$CFG_PIPED_APP_NAME
		setupInstallVariables $app_name;
    fi

    if [[ "$piped" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

    if [[ "$piped" == *[tT]* ]]; then
        pipedToolsMenu;
    fi

	if [[ "$piped" == *[uU]* ]]; then
		dockerUninstallApp $app_name;
	fi

	if [[ "$piped" == *[sS]* ]]; then
		dockerComposeDown $app_name;
	fi

	if [[ "$piped" == *[rR]* ]]; then
        dockerComposeRestart $app_name;
	fi

    if [[ "$piped" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###           Install $app_name"
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
            disallow_used_port=""
        fi
        if [[ $disallow_open_port == "true" ]]; then
            isError "An open port conflict has occured, setup is cancelling..."
            disallow_open_port=""
            return
        else
            isSuccessful "No open port conflicts found, setup is continuing..."
            disallow_open_port=""
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
    piped=n
}