#!/bin/bash

# Category : user
# Description : Nextcloud - Cloud Platform *UNFINISHED* (c/t/u/s/r/i):

installNextcloud()
{
    if [[ "$nextcloud" == *[cCtTuUsSrRiI]* ]]; then
        dockerConfigSetupToContainer silent nextcloud;
        local app_name=$CFG_NEXTCLOUD_APP_NAME
		setupInstallVariables $app_name;
    fi

    if [[ "$nextcloud" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

    if [[ "$nextcloud" == *[uU]* ]]; then
        dockerUninstallApp $app_name;
    fi

    if [[ "$nextcloud" == *[sS]* ]]; then
        dockerComposeDown $app_name;
    fi

    if [[ "$nextcloud" == *[rR]* ]]; then
        dockerComposeRestart $app_name;
    fi

    if [[ "$nextcloud" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###          Install $app_name"
        echo "##########################################"
        echo ""

        local traefik_status=$(dockerCheckAppInstalled "traefik" "docker")
        if [ "$traefik_status" == "not_installed" ]; then
            while true; do
                echo ""
                isNotice "Traefik is not installed, it is recommended..."
                echo ""
                isQuestion "Would you like to install Traefik? (y/n): "
                read -p "" nextcloud_traefik_choice
                if [[ -n "$nextcloud_traefik_choice" ]]; then
                    break
                fi
                isNotice "Please provide a valid input."
            done
            if [[ "$nextcloud_traefik_choice" == [yY] ]]; then
                dockerInstallApp traefik;
            fi
            if [[ "$nextcloud_traefik_choice" == [nN] ]]; then
                isNotice "Installation is contunuing without Traefik, this may lead to issues..."
            fi
        fi

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

        if [ "$traefik_status" == "installed" ]; then
            ((menu_number++))
            echo ""
            echo "---- $menu_number. Setting up the $app_name Traefik config file."
            echo ""

            local result=$(copyResource "traefik" "nextcloud.yml" "etc/dynamic")
            checkSuccess "Copy Nextcloud Traefik configuration"

            dockerConfigSetupFileWithData traefik "nextcloud.yml" "etc/dynamic";

            dockerRestartApp traefik;
        fi

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
        echo "    You can now navigate to your new service using one of the options below : "
        echo ""
        
        menuShowFinalMessages $app_name;
        
		menu_number=0
        sleep 3s
        cd
    fi
    nextcloud=n
}