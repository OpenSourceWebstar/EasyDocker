#!/bin/bash

# Category : user
# Description : OwnCloud - File & Document Cloud (c/u/s/r/i):

installOwncloud()
{
    if [[ "$owncloud" == *[cCtTuUsSrRiI]* ]]; then
        setupConfigToContainer silent owncloud;
        local app_name=$CFG_OWNCLOUD_APP_NAME
        owncloud_version=$CFG_OWNCLOUD_VERSION
		setupInstallVariables $app_name;
    fi

    if [[ "$owncloud" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

	if [[ "$owncloud" == *[uU]* ]]; then
		uninstallApp $app_name;
	fi

	if [[ "$owncloud" == *[sS]* ]]; then
		shutdownApp $app_name;
	fi

    if [[ "$owncloud" == *[rR]* ]]; then
        dockerDownUp $app_name;
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

        setupConfigToContainer "loud" "$app_name" "install";
        isSuccessful "Install folders and Config files have been setup for $app_name."

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Checking & Opening ports if required"
        echo ""

        checkAppPorts $app_name install;
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

        setupComposeFile $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Setup .env file for $app_name"
        echo ""

        local webpage_file="/tmp/webpage.html" 
        # Download the webpage to the temporary directory
        result=$(sudo curl -s "https://doc.owncloud.com/docs/next/server_release_notes.html" > "$webpage_file")
        checkSuccess "Downloading server_release_notes webpage to extract latest version."

        if [ $? -eq 0 ]; then
            # Extract the latest version from the temporary HTML file
            local latest_version=$(sudo grep -o 'Changes in [0-9.-]*' "$webpage_file" | sudo awk -F " " '{print $3}' | sudo sort -V | sudo tail -n 1)
            if [ -n "$latest_version" ]; then
                isSuccessful "Latest Retrieved Version: $latest_version"
                isSuccessful "Using for installation"
                owncloud_version="$latest_version"
            else
                isNotice "Failed to extract the latest version from the webpage."
                isNotice "Defaulting to config value."
            fi

            # Remove the temporary HTML file
            result=$(sudo rm "$webpage_file")
            checkSuccess "Remove the temporary HTML file"
        else
            isNotice "Failed to retrieve the web page."
        fi

if [[ "$public" == "true" ]]; then	

runCommandForDockerInstallUser "cd $containers_dir$app_name && cat << EOF > $containers_dir$app_name/.env
OWNCLOUD_VERSION=$owncloud_version
OWNCLOUD_DOMAIN=$host_setup
OWNCLOUD_TRUSTED_DOMAINS=$host_setup,$ip_setup,$public_ip
ADMIN_USERNAME=$CFG_OWNCLOUD_ADMIN_USERNAME
ADMIN_PASSWORD=$CFG_OWNCLOUD_ADMIN_PASSWORD
HTTP_PORT=$usedport1
EOF"
fi

if [[ "$public" == "false" ]]; then	
runCommandForDockerInstallUser "cd $containers_dir$app_name && cat << EOF > $containers_dir$app_name/.env
OWNCLOUD_VERSION=$owncloud_version
OWNCLOUD_DOMAIN=IPADDRESSHERE
OWNCLOUD_TRUSTED_DOMAINS=IPADDRESSHERE
ADMIN_USERNAME=$CFG_OWNCLOUD_ADMIN_USERNAME
ADMIN_PASSWORD=$CFG_OWNCLOUD_ADMIN_PASSWORD
HTTP_PORT=$usedport1
EOF"
fi
		setupFileWithConfigData $app_name ".env";

		((menu_number++))
        echo ""
        echo "---- $menu_number. Updating file permissions before starting."
        echo ""

		fixPermissionsBeforeStart $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		dockerUpdateAndStartApp $app_name install;

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Running Application specific updates (if required)"
        echo ""

        updateApplicationSpecifics $app_name;

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
        
        menuShowFinalMessages;
		    
		menu_number=0
        sleep 3s
        cd
	fi
	owncloud=n
}