#!/bin/bash

# Category : user
# Description : NGINX - Web Server (c/u/s/r/i):

installNginx()
{
    if [[ "$nginx" == *[cCtTuUsSrRiI]* ]]; then
        dockerConfigSetupToContainer silent nginx;
        local app_name=$CFG_NGINX_APP_NAME
		setupInstallVariables $app_name;
    fi

    if [[ "$nginx" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

    if [[ "$nginx" == *[uU]* ]]; then
        dockerUninstallApp $app_name;
    fi

    if [[ "$nginx" == *[sS]* ]]; then
        dockerComposeDown $app_name;
    fi

    if [[ "$nginx" == *[rR]* ]]; then
        dockerComposeRestart $app_name;
    fi

    if [[ "$nginx" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###      Installing $app_name"
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

        # Copy index file
        result=$(sudo cp -r $install_containers_dir$app_name/resources/index.html "$containers_dir$app_name/html/index.html")
        checkSuccess "Copying over index.html file for NGINX."

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
        isNotice "Your SSH Key(s) are available to download using the link below."
        echo ""
        echo "    URL : http://$ip_setup/"
        echo ""
        isNotice "TIP - Public SSH Keys are stored at /docker/ssh/public/"
        echo ""
        while true; do
            isQuestion "Have you followed the instructions above? (y/n): "
            read -p "" nginx_instructions
            if [[ "$nginx_instructions" == 'y' || "$nginx_instructions" == 'Y' ]]; then
                break
            else
                isNotice "Please confirm the setup or provide a valid input."
            fi
        done

		((menu_number++))
        echo ""
        echo "---- $menu_number. Destroying $app_name service as SSH keys have been downloaded."
        echo ""

        dockerUninstallApp $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Outro Message."
        echo ""
        isNotice "The service has been destroyed for safety reasons"
        isNotice "You can reinstall this service at anytime in the System install menu under the sshinstall option."
        echo ""

        if [[ "$CFG_REQUIREMENT_CONTINUE_PROMPT" == "true" ]]; then
            read -p "Press Enter to continue."
        fi

		menu_number=0
        sleep 3s
        cd
    fi
    nginx=n
}
