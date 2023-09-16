#!/bin/bash

# Description : Cozy - Cloud Platfrom *BROKEN*

installCozy()
{
    app_name=$CFG_COZY_APP_NAME
    host_name=$CFG_COZY_HOST_NAME
    domain_number=$CFG_COZY_DOMAIN_NUMBER
    public=$CFG_COZY_PUBLIC
	#port=$CFG_COZY_PORT

	# Custom Cozy Variables
	# Additional non default apps to be installed
	# List here - https://github.com/vsellier/easy-cozy/blob/master/application.sh
	cozy_user_1=test1
	cozy_user_1_apps_enabled=true
	cozy_user_1_apps="banks contacts"

    if [[ "$cozy" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

    if [[ "$cozy" == *[uU]* ]]; then
        uninstallApp;
    fi

    if [[ "$cozy" == *[sS]* ]]; then
        shutdownApp;
    fi

    if [[ "$cozy" == *[rR]* ]]; then
        dockerDownUpDefault;
    fi

    if [[ "$cozy" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###           Install $app_name"
        echo "##########################################"
        echo ""

		((menu_number++))
        echo ""
        echo "---- $menu_number. Checking DNS entry and IP for setup"
        echo ""

		setupIPsAndHostnames;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Pulling from $app_name GitHub."
        echo ""

		result=$(sudo -u $easydockeruser git clone https://github.com/vsellier/easy-cozy.git $install_dir/$app_name)
		checkSuccess "Cloning the Easy-Cozy from GitHub"
		
		result=$(copyFile $install_dir/$app_name/env.template $install_dir/$app_name/.env | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" 2>&1)
		checkSuccess "Coping .env template into .env for usage"

		result=$(sudo sed -i "s|DATABASE_DIRECTORY=/var/lib/cozy/db|DATABASE_DIRECTORY=$install_dir/$app_name/db|g" $install_dir/$app_name/.env)
		checkSuccess "Update database directory to the correct install path"

		result=$(sudo sed -i "s|STORAGE_DIRECTORY=/var/lib/cozy/storage/STORAGE_DIRECTORY=$install_dir/$app_name/storage/g" $install_dir/$app_name/.env)
		checkSuccess "Update storage directory to the correct install path"

		result=$(sudo sed -i "s|ACME_DIRECTORY=/var/lib/acme|ACME_DIRECTORY=$install_dir/$app_name/acme|g" $install_dir/$app_name/.env)
		checkSuccess "Update acme directory to the correct install path"

		result=$(sudo sed -i "s|COZY_TLD=cozy.mydomain.tld|COZY_TLD=cozy.$domain_full|g" $install_dir/$app_name/.env)
		checkSuccess "Update the domain name to $domain_full"

		result=$(sudo sed -i "s|EMAIL=bofh@mydomain.tld|EMAIL=$CFG_EMAIL|g" $install_dir/$app_name/.env)
		checkSuccess "Update the email to $CFG_EMAIL"

		result=$(sudo sed -i "s|COZY_ADMIN_PASSPHRASE=changeme|COZY_ADMIN_PASSPHRASE=$CFG_COZY_ADMIN_PASSPHRASE|g" $install_dir/$app_name/.env)
		checkSuccess "Update the Admin Passphrase to the specified password in the apps config"
		
		result=$(mkdirFolders $install_dir/$app_name/db $install_dir/$app_name/storage)
		checkSuccess "Creating db and storage folders"

		setupComposeFileApp;

		result=$(sudo sed -i '35,$ d' $install_dir/$app_name/docker-compose.yml)
		checkSuccess "Removing line 35 from the docker-compose.yml file"

		result=$(sudo sed -i "s|- \"traefik|  # - \"traefik|g" $install_dir/$app_name/docker-compose.yml)
		checkSuccess "Disabling all outdated Traefik values in docker-compose.yml "

		result=$(sudo sed -i "s|labels:|#labels:|g" $install_dir/$app_name/docker-compose.yml)
		checkSuccess "Disabling labels in docker-compose.yml as we have custom values."

		editComposeFileApp;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		dockerDownUpDefault;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Updating file permissions before starting."
        echo ""

		fixPermissionsBeforeStart $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Setting up Users with their applications for $app_name"
        echo ""

		# Setting up a single instance of Cozy
		result=$(cd $install_dir/$app_name && sudo -u $easydockeruser ./create-instance.sh $cozy_user_1)
		checkSuccess "Creating instance of $app_name for $cozy_user_1"

		if [[ "$cozy_user_1_apps_enabled" == true ]]; then
			result=$(sudo -u $easydockeruser ./application.sh $cozy_user_1 $cozy_user_1_apps)
			checkSuccess "Setting up applications for $app_name for $cozy_user_1"
		fi

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
        echo "---- $menu_number. You can find $app_name files at $install_dir$app_name"
        echo ""
        echo "    You can now navigate to your $app_name service using any of the options below : "
        echo ""
        echo "    Public : https://$host_setup/"
        echo "    External : http://$public_ip:$port/"
        echo "    Local : http://$ip_setup:$port/"
        echo ""
		     
		menu_number=0
        sleep 3s
        cd
    fi
    cozy=n
}