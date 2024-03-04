#!/bin/bash

# Category : privacy
# Description : Vaultwarden - Password Manager (c/u/s/r/i):

installVaultwarden()
{
    if [[ "$vaultwarden" == *[cCtTuUsSrRiI]* ]]; then
        dockerConfigSetupToContainer silent vaultwarden;
        local app_name=$CFG_VAULTWARDEN_APP_NAME
		setupInstallVariables $app_name;
    fi

    if [[ "$vaultwarden" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

	if [[ "$vaultwarden" == *[uU]* ]]; then
		dockerUninstallApp $app_name;
	fi

	if [[ "$vaultwarden" == *[sS]* ]]; then
		dockerComposeDown $app_name;
	fi

	if [[ "$vaultwarden" == *[rR]* ]]; then
        dockerComposeRestart $app_name;
	fi

    if [[ "$vaultwarden" == *[iI]* ]]; then
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

        dockerComposeRestartFile $app_name;

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
	vaultwarden=n
}
