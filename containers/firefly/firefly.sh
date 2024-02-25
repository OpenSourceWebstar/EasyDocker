#!/bin/bash

# Category : privacy
# Description : Firefly - Money Budgetting (c/u/s/r/i):

installFirefly()
{
    if [[ "$firefly" == *[cCtTuUsSrRiI]* ]]; then
        dockerConfigSetupToContainer silent firefly;
        local app_name=$CFG_FIREFLY_APP_NAME
		setupInstallVariables $app_name;
    fi
    
    if [[ "$firefly" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

	if [[ "$firefly" == *[uU]* ]]; then
		dockerUninstallApp $app_name;
	fi

	if [[ "$firefly" == *[sS]* ]]; then
		dockerComposeDown $app_name;
	fi

    if [[ "$firefly" == *[rR]* ]]; then
        dockerComposeRestart $app_name;
    fi

    if [[ "$firefly" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###      Install $app_name"
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

        dockerComposeRestartFile $app_name;

        result=$(rm -rf "$containers_dir$app_name/resources/.env")
        checkSuccess "Removing old .env file"
        result=$(rm -rf "$containers_dir$app_name/resources/.db.env")
        checkSuccess "Removing old .db.env file"

        local result=$(copyResource "$app_name" ".env" "")
        checkSuccess "Copying the .env for $app_name"
        local result=$(copyResource "$app_name" ".db.env" "")
        checkSuccess "Copying the .db.env for $app_name"

        dockerConfigSetupFileWithData $app_name ".env";
        dockerConfigSetupFileWithData $app_name ".db.env";

        local APP_KEY=$(head /dev/urandom | LC_ALL=C tr -dc 'A-Za-z0-9' | head -c 32 && echo)
        result=$(sudo sed -i "s|SomeRandomStringOf32CharsExactly|${APP_KEY}|" "$containers_dir$app_name/.db.env")
        checkSuccess "Enabling environment in the docker-compose file."

        local random_password=$(openssl rand -base64 12 | tr -d '+/=')
        result=$(sudo sed -i "s|secret_firefly_password|${random_password}|" "$containers_dir$app_name/.env")
        checkSuccess "Updating the MYSQL password in .env."
        result=$(sudo sed -i "s|secret_firefly_password|${random_password}|" "$containers_dir$app_name/.db.env")
        checkSuccess "Updating the MYSQL password in .db.env."

        if [[ $public == "true" ]]; then
            result=$(sudo sed -i "s|APP_URL=http://localhost|APP_URL=https://$host_setup|" "$containers_dir$app_name/.env")
            checkSuccess "Enabling environment in the docker-compose file."
            result=$(sudo sed -i "s|TRUSTED_PROXIES=|TRUSTED_PROXIES=*|" "$containers_dir$app_name/.env")
            checkSuccess "Enabling TRUSTED_PROXIES in the .env file."
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
        echo "---- $menu_number. Adding $app_name to the Apps Database table."
        echo ""

		databaseInstallApp $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running Headscale setup (if required)"
        echo ""

		setupHeadscale $app_name;

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
	firefly=n
}