#!/bin/bash

# Category : old
# Description : Cozy - Cloud Platfrom *BROKEN* (c/u/s/r/i):

installCozy()
{
    if [[ "$cozy" == *[cCtTuUsSrRiI]* ]]; then
        setupConfigToContainer silent cozy;
        local app_name=$CFG_COZY_APP_NAME
        # Custom Cozy Variables
        # Additional non default apps to be installed
        # List here - https://github.com/vsellier/easy-cozy/blob/master/application.sh
        cozy_user_1=test1
        cozy_user_1_apps_enabled=true
        cozy_user_1_apps="banks contacts"
		setupInstallVariables $app_name;
    fi

    if [[ "$cozy" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

    if [[ "$cozy" == *[uU]* ]]; then
        uninstallApp $app_name;
    fi

    if [[ "$cozy" == *[sS]* ]]; then
        shutdownApp $app_name;
    fi

    if [[ "$cozy" == *[rR]* ]]; then
        dockerDownUp $app_name;
    fi

    if [[ "$cozy" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###           Install $app_name"
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
        echo "---- $menu_number. Pulling from $app_name GitHub."
        echo ""

		local result=$(sudo -u $sudo_user_name git clone https://github.com/vsellier/easy-cozy.git $containers_dir/$app_name)
		checkSuccess "Cloning the Easy-Cozy from GitHub"
		
		local result=$(copyFile "loud" $containers_dir/$app_name/env.template $containers_dir/$app_name/.env $CFG_DOCKER_INSTALL_USER | sudo -u $sudo_user_name tee -a "$logs_dir/$docker_log_file" 2>&1)
		checkSuccess "Coping .env template into .env for usage"

		local result=$(sudo sed -i "s|DATAdocker_dirECTORY=/var/lib/cozy/db|DATAdocker_dirECTORY=$containers_dir/$app_name/db|g" $containers_dir/$app_name/.env)
		checkSuccess "Update database directory to the correct install path"

		local result=$(sudo sed -i "s|STORAGE_DIRECTORY=/var/lib/cozy/storage/STORAGE_DIRECTORY=$containers_dir/$app_name/storage/g" $containers_dir/$app_name/.env)
		checkSuccess "Update storage directory to the correct install path"

		local result=$(sudo sed -i "s|ACME_DIRECTORY=/var/lib/acme|ACME_DIRECTORY=$containers_dir/$app_name/acme|g" $containers_dir/$app_name/.env)
		checkSuccess "Update acme directory to the correct install path"

		local result=$(sudo sed -i "s|COZY_TLD=cozy.mydomain.tld|COZY_TLD=cozy.$domain_full|g" $containers_dir/$app_name/.env)
		checkSuccess "Update the domain name to $domain_full"

		local result=$(sudo sed -i "s|EMAIL=bofh@mydomain.tld|EMAIL=$CFG_EMAIL|g" $containers_dir/$app_name/.env)
		checkSuccess "Update the email to $CFG_EMAIL"

		local result=$(sudo sed -i "s|COZY_ADMIN_PASSPHRASE=changeme|COZY_ADMIN_PASSPHRASE=$CFG_COZY_ADMIN_PASSPHRASE|g" $containers_dir/$app_name/.env)
		checkSuccess "Update the Admin Passphrase to the specified password in the apps config"
		
		local result=$(mkdirFolders "loud" $CFG_DOCKER_INSTALL_USER $containers_dir/$app_name/db $containers_dir/$app_name/storage)
		checkSuccess "Creating db and storage folders"

        setupComposeFile $app_name;

		local result=$(sudo sed -i '35,$ d' $containers_dir/$app_name/docker-compose.yml)
		checkSuccess "Removing line 35 from the docker-compose.yml file"

		local result=$(sudo sed -i "s|- \"traefik|  # - \"traefik|g" $containers_dir/$app_name/docker-compose.yml)
		checkSuccess "Disabling all outdated Traefik values in docker-compose.yml "

		local result=$(sudo sed -i "s|labels:|#labels:|g" $containers_dir/$app_name/docker-compose.yml)
		checkSuccess "Disabling labels in docker-compose.yml as we have custom values."

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
        echo "---- $menu_number. Setting up Users with their applications for $app_name"
        echo ""

		# Setting up a single instance of Cozy
		local result=$(cd $containers_dir/$app_name && sudo -u $sudo_user_name ./create-instance.sh $cozy_user_1)
		checkSuccess "Creating instance of $app_name for $cozy_user_1"

		if [[ "$cozy_user_1_apps_enabled" == true ]]; then
			local result=$(sudo -u $sudo_user_name ./application.sh $cozy_user_1 $cozy_user_1_apps)
			checkSuccess "Setting up applications for $app_name for $cozy_user_1"
		fi

		((menu_number++))
		echo ""
        echo "---- $menu_number. Adding $app_name to the Apps Database table."
        echo ""

		databaseInstallApp $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. You can find $app_name files at $containers_dir$app_name"
        echo ""
        echo "    You can now navigate to your $app_name service using any of the options below : "
        echo ""
        echo "    Public : https://$host_setup/"
        echo "    External : http://$public_ip:$usedport1/"
        echo "    Local : http://$ip_setup:$usedport1/"
        echo ""
		     
		menu_number=0
        sleep 3s
        cd
    fi
    cozy=n
}