#!/bin/bash

# Category : privacy
# Description : Actual - Money Budgetting (c/u/s/r/i):

installActual()
{
    passedValue="$1"

    if [[ "$passedValue" == "install" ]]; then
        actual=i
    fi

    if [[ -n "$actual" || "$actual" != "n" ]]; then
        setupConfigToContainer actual;
        app_name=$CFG_ACTUAL_APP_NAME
    fi
    
    if [[ "$actual" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

	if [[ "$actual" == *[uU]* ]]; then
		uninstallApp $app_name;
	fi

	if [[ "$actual" == *[sS]* ]]; then
		shutdownApp;
	fi

    if [[ "$actual" == *[rR]* ]]; then
		setupInstallVariables $app_name;
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
        echo "---- $menu_number. Checking custom DNS entry and IP for setup"
        echo ""

		setupInstallVariables $app_name;

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

			result=$(mkdirFolders -p $install_dir$app_name/actual-data)
			checkSuccess "Create actual-data folder"
			
			result=$(copyFile $containers_dir$app_name/resources/$app_name/config.json $install_dir$app_name/actual-data/config.json | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" 2>&1)
			checkSuccess "Copying config.json to actual-data folder"

			result=$(copyFile $ssl_dir/$ssl_crt $install_dir$app_name/actual-data/cert.pem | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" 2>&1)
			checkSuccess "Copying cert to actual-data folder"

			result=$(copyFiles $ssl_dir/$ssl_key $install_dir$app_name/actual-data/key.pem | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" 2>&1)
			checkSuccess "Copying key to actual-data folder"
			
		else
			checkSuccess "Self Signed SSL Certificate not found, this may cause an issue!"
		fi

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		whitelistAndStartApp $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Updating file permissions before starting."
        echo ""

		fixPermissionsBeforeStart;

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Opening ports if required"
        echo ""

        openAppPorts $app_name;

		((menu_number++))
		echo ""
        echo "---- $menu_number. Adding $app_name to the Apps Database table."
        echo ""

		databaseInstallApp;

		((menu_number++))
        echo ""
        echo "---- $menu_number. You can find $app_name files at $install_dir$app_name"
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