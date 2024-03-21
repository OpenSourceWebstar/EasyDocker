#!/bin/bash

# Category : user
# Description : Rustdesk - Remote Desktop Server (c/u/s/r/i):

installRustdesk()
{
    if [[ "$rustdesk" == *[cCtTuUsSrRiI]* ]]; then
        dockerConfigSetupToContainer silent rustdesk;
        local app_name=$CFG_RUSTDESK_APP_NAME
		setupInstallVariables $app_name;
    fi

    if [[ "$rustdesk" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

    if [[ "$rustdesk" == *[uU]* ]]; then
        dockerUninstallApp $app_name;
    fi

    if [[ "$rustdesk" == *[sS]* ]]; then
        dockerComposeDown $app_name;
    fi

    if [[ "$rustdesk" == *[rR]* ]]; then
        dockerComposeRestart $app_name;
    fi

    if [[ "$rustdesk" == *[iI]* ]]; then
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
        echo "---- $menu_number. Updating $app_name with an encryption key."
        echo ""

        local rustdesk_timeout=10
        local rustdesk_counter=0
        local public_key_file="$containers_dir$app_name/hbbs/id_ed25519.pub"

        # Loop to check for the existence of the file every second
        while [ ! -f "$public_key_file" ]; do
            if [ "$rustdesk_counter" -ge "$rustdesk_timeout" ]; then
                isNotice "File not found after 10 seconds. Exiting..."
                break
            fi

            isNotice "Waiting for the file to appear..."
            read -t 1 # Wait for 1 second

            # Increment the counter
            local rustdesk_counter=$((rustdesk_counter + 1))
        done

        # Extract the public key from the specified file
        local public_key=$(cat "$public_key_file")
        if [[ $compose_setup == "default" ]]; then
            local compose_file="$containers_dir$app_name/docker-compose.yml"
        elif [[ $compose_setup == "app" ]]; then
            local compose_file="$containers_dir$app_name/docker-compose.$app_name.yml"
        fi

        # Check if the desired public key is already set in the Docker Compose file
        if sudo grep -q "$public_key" "$compose_file"; then
            isNotice "Docker Compose file is already set up with the public key."
        else
            # Update the Docker Compose file using `sed`
            result=$(sudo sed -i "s|${host_setup}:${usedport3}|${host_setup}:${usedport3} -k $public_key|" "$compose_file")
            checkSuccess "Update Docker Compose file with the public key."
        fi

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
        echo "    You can now navigate to your new service using one of the options below : "
        echo ""
        echo "    Your Rustdesk Key is : $public_key"
        echo ""

        menuShowFinalMessages $app_name;

		menu_number=0
        sleep 3s
        cd
    fi
    rustdesk=n
}