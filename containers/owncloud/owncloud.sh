#!/bin/bash

# Category : user
# Description : OwnCloud - File & Document Cloud (c/u/s/r/i):

installOwncloud()
{
    if [[ "$owncloud" == *[cCtTuUsSrRiI]* ]]; then
        dockerConfigSetupToContainer silent owncloud;
        local app_name=$CFG_OWNCLOUD_APP_NAME
        owncloud_version=$CFG_OWNCLOUD_VERSION
		setupInstallVariables $app_name;
    fi

    if [[ "$owncloud" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

	if [[ "$owncloud" == *[uU]* ]]; then
		dockerUninstallApp $app_name;
	fi

	if [[ "$owncloud" == *[sS]* ]]; then
		dockerComposeDown $app_name;
	fi

    if [[ "$owncloud" == *[rR]* ]]; then
        dockerComposeRestart $app_name;
    fi

    if [[ "$owncloud" == *[iI]* ]]; then
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
        echo "---- $menu_number. Obtain latest version number of $app_name"
        echo ""
        
        local webpage_file="/tmp/webpage.html"

        # Download the webpage to the temporary directory
        curl -s "https://doc.owncloud.com/docs/next/server_release_notes.html" > "$webpage_file"
        if [ $? -eq 0 ]; then
            # Extract the latest version from the temporary HTML file
            local latest_version=$(grep -o 'Changes in [0-9.-]*' "$webpage_file" | awk -F " " '{print $3}' | sort -V | tail -n 1)
            if [ -n "$latest_version" ]; then
                isSuccessful "Latest Retrieved Version: $latest_version"
                isSuccessful "Using for installation"
                owncloud_version="$latest_version"
            else
                isNotice "Failed to extract the latest version from the OwnCloud website."
                isNotice "Defaulting to config value : $CFG_OWNCLOUD_VERSION."
                owncloud_version="$CFG_OWNCLOUD_VERSION"
            fi

            # Remove the temporary HTML file
            rm "$webpage_file"
            if [ $? -eq 0 ]; then
                isSuccessful "Removed the temporary HTML file"
            else
                isNotice "Failed to remove the temporary HTML file"
            fi
        else
            isNotice "Failed to retrieve the web page."
        fi

		((menu_number++))
        echo ""
        echo "---- $menu_number. Setup .env file for $app_name"
        echo ""

        local result=$(copyResource "$app_name" ".env" "")
        checkSuccess "Copying the .env for $app_name"

        local file_path="$containers_dir$app_name/.env"

        local result=$(sudo sed -i \
            -e "s|OWNCLOUD_SETUP_VERSION|$owncloud_version|g" \
            -e "s|OWNCLOUD_SETUP_ADMIN_USERNAME|$CFG_OWNCLOUD_ADMIN_USERNAME|g" \
            -e "s|OWNCLOUD_SETUP_ADMIN_PASSWORD|$CFG_OWNCLOUD_ADMIN_PASSWORD|g" \
            -e "s|OWNCLOUD_SETUP_HTTP_PORT|$usedport1|g" \
        "$file_path")
        checkSuccess "Updating $file_name for $app_name"

        if [[ "$public" == "true" ]]; then
            local result=$(sudo sed -i \
                -e "s|OWNCLOUD_SETUP_DOMAIN|$host_setup|g" \
                -e "s|OWNCLOUD_SETUP_TRUSTED_DOMAINS|$host_setup,$ip_setup,$public_ip_v4|g" \
            "$file_path")
            checkSuccess "Updating $file_name for $app_name"
        fi

        if [[ "$public" == "false" ]]; then
            local result=$(sudo sed -i \
                -e "s|OWNCLOUD_SETUP_DOMAIN|$ip_setup|g" \
                -e "s|OWNCLOUD_SETUP_TRUSTED_DOMAINS|$ip_setup|g" \
            "$file_path")
            checkSuccess "Updating $file_name for $app_name"
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
	owncloud=n
}