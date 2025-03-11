#!/bin/bash

# Category : user
# Description : Seafile - File Sync and Share (c/u/s/r/i):

installSeafile()
{
    if [[ "$seafile" == *[cCtTuUsSrRiI]* ]]; then
        dockerConfigSetupToContainer silent seafile;
        local app_name=$CFG_SEAFILE_APP_NAME
	    setupInstallVariables $app_name;
    fi

    if [[ "$seafile" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

    if [[ "$seafile" == *[uU]* ]]; then
        dockerUninstallApp $app_name;
    fi

    if [[ "$seafile" == *[sS]* ]]; then
        dockerComposeDown $app_name;
    fi

    if [[ "$seafile" == *[rR]* ]]; then
        dockerComposeRestart $app_name;
    fi

    if [[ "$seafile" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###          Install $app_name"
        echo "##########################################"
        echo ""

		((menu_number++))
        echo ""
        echo "---- $menu_number. Setting up install folders and config file for $app_name."
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
        echo "---- $menu_number. Updating defaul redis port and restarting $app_name"
        echo ""

        local seafile_timeout=180
        local seafile_counter=0
        local seafile_settings="$containers_dir$app_name/seafile-data/seafile/conf/seahub_settings.py"
        local check_interval=15  # Print status every 15 seconds

        while [ ! -f "$seafile_settings" ]; do
            if [ "$seafile_counter" -ge "$seafile_timeout" ]; then
                isNotice "File seahub_settings.py not found after $seafile_timeout seconds. Exiting..."
                break
            fi

            # Only print message every $check_interval seconds
            if (( seafile_counter % check_interval == 0 )); then
                isNotice "Waiting for seahub_settings.py to appear... (Checked for $seafile_counter seconds)"
            fi

            sleep 1  # Wait for 1 second
            ((seafile_counter++))
        done

        # Check if the file was found or if we timed out
        if [ -f "$seafile_settings" ]; then
            isNotice "File found! Updating the default Redis port..."
            sudo sed -i "s/11211/$PORT2/g" "$seafile_settings"
            checkSuccess "Updated default Redis port for $app_name"

            dockerComposeRestart "$app_name"
        fi

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
    seafile=n
}
