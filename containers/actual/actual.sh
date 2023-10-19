#!/bin/bash

# Category : privacy
# Description : Actual - Money Budgetting (c/u/s/r/i):

installActual()
{
    local passedValue="$1"

    if [[ "$passedValue" == "install" ]]; then
        actual=i
    fi

    if [[ "$actual" == *[cCtTuUsSrRiI]* ]]; then
        setupConfigToContainer --silent actual;
        local app_name=$CFG_ACTUAL_APP_NAME
		setupInstallVariables $app_name;
    fi
    
    if [[ "$actual" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

	if [[ "$actual" == *[uU]* ]]; then
		uninstallApp $app_name;
	fi

	if [[ "$actual" == *[sS]* ]]; then
		shutdownApp $app_name;
	fi

    if [[ "$actual" == *[rR]* ]]; then
        if [[ $compose_setup == "default" ]]; then
		    dockerDownUpDefault $app_name;
        elif [[ $compose_setup == "app" ]]; then
            dockerDownUpAdditionalYML $app_name;
        fi
    fi

    if [[ "$actual" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###      Install $app_name"
        echo "##########################################"
        echo ""

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Checking & Checking & Opening ports if required"
        echo ""

        checkAppPorts $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Setting up install folder and config file for $app_name."
        echo ""

        setupConfigToContainer $app_name install;
        isSuccessful "Install folders and Config files have been setup for $app_name."

		((menu_number++))
        echo ""
        echo "---- $menu_number. Pulling a default $app_name docker-compose.yml file."
        echo ""

        if [[ $compose_setup == "default" ]]; then
		    setupComposeFileNoApp $app_name;
        elif [[ $compose_setup == "app" ]]; then
            setupComposeFileApp $app_name;
        fi

		# SSL Cert is needed to load, using self signed
		if [ -f "$ssl_dir$ssl_key" ]; then
			checkSuccess "Self Signed SSL Certificate found, installing...."

			local result=$(mkdirFolders $containers_dir$app_name/actual-data)
			checkSuccess "Create actual-data folder"
			
			local result=$(copyFile $install_containers_dir$app_name/resources/config.json $containers_dir$app_name/actual-data/config.json | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" 2>&1)
			checkSuccess "Copying config.json to actual-data folder"

			local result=$(copyFile $ssl_dir$ssl_crt $containers_dir$app_name/actual-data/cert.pem | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" 2>&1)
			checkSuccess "Copying cert to actual-data folder"

			local result=$(copyFile $ssl_dir$ssl_key $containers_dir$app_name/actual-data/key.pem | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" 2>&1)
			checkSuccess "Copying key to actual-data folder"
			
		else
			checkSuccess "Self Signed SSL Certificate not found, this may cause an issue!"
		fi

        if [ "$public" == "false" ]; then
            # Enable local SSL
            result=$(sudo sed -i 's|^#environment|environment|' "$containers_dir$app_name/docker-compose.yml")
            checkSuccess "Enabling environment in the docker-compose file."
            result=$(sudo sed -i 's|^# - ACTUAL_HTTPS| - ACTUAL_HTTPS|' "$containers_dir$app_name/docker-compose.yml")
            checkSuccess "Enabling the HTTPS variables in the docker-compose file."
        fi

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		whitelistAndStartApp $app_name install;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Updating file permissions before starting."
        echo ""

		fixPermissionsBeforeStart $app_name;

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
        echo "    Public : https://$host_setup/"
        echo "    External : http://$public_ip:$port/"
        echo "    Local : http://$ip_setup:$port/"
        echo ""

		menu_number=0
        sleep 3s
        cd
	fi
	actual=n
}