#!/bin/bash

# Description : Actual - Money Budgetting

installActual()
{
    app_name=$CFG_ACTUAL_APP_NAME
    host_name=$CFG_ACTUAL_HOST_NAME
    domain_number=$CFG_ACTUAL_DOMAIN_NUMBER
    public=$CFG_ACTUAL_PUBLIC
	port=$CFG_ACTUAL_PORT
    
    if [[ "$actual" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

	if [[ "$actual" == *[uU]* ]]; then
		uninstallApp;
	fi

	if [[ "$actual" == *[sS]* ]]; then
		shutdownApp;
	fi

    if [[ "$actual" == *[rR]* ]]; then
        dockerDownUpDefault;
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

		setupIPsAndHostnames;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Pulling a default $app_name docker-compose.yml file."
        echo ""

		setupComposeFileNoApp;
		editComposeFileDefault;

		# SSL Cert is needed to load, using self signed
		if [ -f "$ssl_dir$ssl_key" ]; then
			checkSuccess "Self Signed SSL Certificate found, installing...."

			result=$(mkdirFolders -p $install_path$app_name/actual-data)
			checkSuccess "Create actual-data folder"
			
			result=$(copyFile $script_dir/resources/$app_name/config.json $install_path$app_name/actual-data/config.json | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" 2>&1)
			checkSuccess "Copying config.json to actual-data folder"

			result=$(copyFile $ssl_dir/$ssl_crt $install_path$app_name/actual-data/cert.pem | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" 2>&1)
			checkSuccess "Copying cert to actual-data folder"

			result=$(copyFiles $ssl_dir/$ssl_key $install_path$app_name/actual-data/key.pem | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" 2>&1)
			checkSuccess "Copying key to actual-data folder"
			
		else
			checkSuccess "Self Signed SSL Certificate not found, this may cause an issue!"
		fi

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		dockerDownUpDefault;

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Opening ports if required"
        echo ""

        openAppPorts;

		((menu_number++))
		echo ""
        echo "---- $menu_number. Adding $app_name to the Apps Database table."
        echo ""

		databaseInstallApp;

		((menu_number++))
        echo ""
        echo "---- $menu_number. You can find $app_name files at $install_path$app_name"
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