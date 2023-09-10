#!/bin/bash

app_name="$1"

installMailcow()
{
    app_name=$CFG_MAILCOW_APP_NAME
    host_name=$CFG_MAILCOW_HOST_NAME
    domain_number=$CFG_MAILCOW_DOMAIN_NUMBER
    public=$CFG_MAILCOW_PUBLIC
	easy_setup=$CFG_MAILCOW_EASY_SETUP
	using_caddy=$CFG_MAILCOW_USING_CADDY

	if [[ "$mailcow" == *[uU]* ]]; then
		uninstallApp;
	fi

	if [[ "$mailcow" == *[sS]* ]]; then
		shutdownApp;
	fi

	if [[ "$mailcow" == *[rR]* ]]; then
		dockerUpDownAdditionalYML;
	fi

    if [[ "$mailcow" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###           Install $app_name"
        echo "##########################################"
        echo ""

		((menu_number++))
        echo ""
        echo "---- $menu_number. Checking custom DNS entry and IP for setup"
        echo ""

		setupIPsAndHostnames;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Initial setup options"
        echo ""

		if [[ "$easy_setup" == "true" ]]; then
			COWP80C=8022
			COWP443C=4432
			COWCD=n
			COWLE=y
			COWPORT=y
		else
			isQuestion "8022 will be used for the HTTP Port, are you happy with this? (y/n): "
			read -rp "" COWP80_PROMPT
			if [[ "$COWP80_PROMPT" == [nN] ]]; then
				while true; do
					read -rp "Enter the port you want to use instead of 8022 (#): " COWP80C
					if [[ $COWP80C =~ ^[0-9]+$ ]]; then
						echo "Given valid port $COWP80C"
						break
					else
						echo "Ports should only contain numbers, please try again."
					fi
				done
			else
				COWP80C=8022
			fi

			isQuestion "4432 will be used for the HTTPS Port, are you happy with this? (y/n): "
			read -rp "" COWP443_PROMPT

			if [[ "$COWP443_PROMPT" == [nN] ]]; then
				while true; do
					read -rp "Enter the port you want to use instead of 4432 (#): " COWP443C
					if [[ $COWP443C =~ ^[0-9]+$ ]]; then
						echo "Given valid port $COWP443C"
						break
					else
						echo "Ports should only contain numbers, please try again."
					fi
				done
			else
				COWP443C=4432
			fi

			isQuestion "Do you want to use ClamD Antivirus? (uses lots of resources) (y/n): "
			read -rp "" COWCD
		fi
		
		((menu_number++))
        echo ""
        echo "---- $menu_number. Checking to see if all ports are available"
        echo ""
		
		if [[ "$easy_setup" == "false" ]]; then
			local ports_to_scan="25|$COWP80C|110|143|$COWP443C|465|587|993|995|4190"
			local scan_result

			scan_result=$(sudo -u $easydockeruser ss -tlpn | sudo -u $easydockeruser grep -E -w "$ports_to_scan")

			if [[ -n "$scan_result" ]]; then
				isError "Some of the specified ports are not free:"
				isError "Result : $scan_result"
				exit 1
			else
				isSuccessful "All specified ports are free. No conflicts detected."
			fi

			isQuestion "Are the Ports clear for Mailcow to install? (y/n): "
			read -rp "" COWPORT
		fi

		((menu_number++))
	    echo ""
        echo "---- $menu_number. Pulling Mailcow GitHub repo into the $install_path$app_name folder"
        echo ""

		result=$(sudo -u $easydockeruser git clone https://github.com/mailcow/mailcow-dockerized $install_path/mailcow)
		checkSuccess "Cloning Mailcow Dockerized GitHub repo"

		result=$(sudo -u $easydockeruser cp $script_dir/containers/docker-compose.$app_name.yml $install_path$app_name/docker-compose.$app_name.yml | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" 2>&1)
		checkSuccess "Copying docker-compose.$app_name.yml to the $app_name folder"

		((menu_number++))
	    echo ""
        echo "---- $menu_number. Pulling Mailcow GitHub repo into the /docker/ folder"
        echo ""

		# Custom values from files
		result=$(sudo -u $easydockeruser sed -i "s/DOMAINNAMEHERE/$domain_full/g" $install_path$app_name/docker-compose.$app_name.yml)
		checkSuccess "Updating Domain Name in the docker-compose.$app_name.yml file"

		result=$(sudo -u $easydockeruser sed -i "s/IPADDRESSHERE/$ip_setup/g" $install_path$app_name/docker-compose.$app_name.yml)
		checkSuccess "Updating IP Address in the docker-compose.$app_name.yml file"

		result=$(sudo -u $easydockeruser sed -i "s/PORTHERE/$COWP80C/g" $install_path$app_name/docker-compose.$app_name.yml)
		checkSuccess "Updating Port to $$COWP80C in the docker-compose.$app_name.yml file"
		
		if [[ "$using_caddy" == "false" ]]; then
			# Setup SSL Transfer scripts
			result=$(sudo -u $easydockeruser cp $script_dir/resources/caddy/caddy-to-mailcow-ssl.sh $install_path$app_name/caddy-to-mailcow-ssl.sh | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" 2>&1)
			checkSuccess "Copying SSL caddy-to-mailcow-ssl.sh script to docker folder."
			
			result=$(sudo -u $easydockeruser sed -i "s/DOMAINNAMEHERE/mail.$domain_full/g" $install_path$app_name/caddy-to-mailcow-ssl.sh)
			checkSuccess "Setting Domain Name in caddy-to-mailcow-ssl.sh"
			
			result=$(sudo -u $easydockeruser chmod 0755 /docker/mailcow/caddy-to-mailcow-ssl.sh)
			checkSuccess "Updating permissions for caddy-to-mailcow-ssl.sh"
			
			# Setup crontab
			job="0 * * * * /bin/bash $install_path$app_name/caddy-to-mailcow-ssl.sh"
			if ( sudo -u $easydockeruser crontab -l | grep -q -F "$job" ); then
				isNotice "Cron job already exists, ignoring..."
			else
			( sudo -u $easydockeruser crontab -l ; echo "$job" ) | sudo -u $easydockeruser crontab -
				isSuccessful "Cron job added successfully!"
			fi
		fi
		
		# Script to setup Mailcow
		result=$(cd mailcow && sudo -u $easydockeruser ./generate_config.sh)
		checkSuccess "Running Mailcow config generation script"

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running configuration edits to mailserver.conf"
        echo ""

		if [[ "$COWP80_PROMPT" == [yY] ]]; then
        	result=$(sed -i 's/HTTP_PORT=80/HTTP_PORT='$COWP80C'/' $install_path/mailcow/mailcow.conf)
        	checkSuccess "Updating the mailserver.conf to custom http port"
		fi
		if [[ "$COWP443_PROMPT" == [yY] ]]; then
        	result=$(sed -i 's/HTTPS_PORT=443/HTTPS_PORT='$COWP443C'/' $install_path/mailcow/mailcow.conf)
        	checkSuccess "Updating the mailserver.conf to custom https port"
		fi
		if [[ "$COWLE" == [yY] ]]; then
        	result=$(sed -i 's/SKIP_LETS_ENCRYPT=n/SKIP_LETS_ENCRYPT=y/' $install_path/mailcow/mailcow.conf)
        	checkSuccess "Updating the mailserver.conf to disable SSL install"
		fi
		if [[ "$COWCD" == [nN] ]]; then
        	result=$(sed -i 's/SKIP_CLAMD=n/SKIP_CLAMD=y/' $install_path/mailcow/mailcow.conf)
        	checkSuccess "Updating the mailserver.conf to disable ClamD Antivirus"
		fi

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		dockerUpDownAdditionalYML;

		((menu_number++))
		echo ""
        echo "---- $menu_number. Adding $app_name to the Apps Database table."
        echo ""

		databaseInstallApp;

		((menu_number++))
        echo ""
        echo "---- $menu_number. You can find $app_name files at $install_path$app_name"
        echo ""
        echo "    You can now navigate to your $app_name service using any of the options below : "
        echo ""
        echo "    Public : https://$host_setup/"
        echo "    External : http://$public_ip:$port/ OR https://$public_ip:$COWP443/"
        echo "    Local : http://$ip_setup:$port/ OR htts://$ip_setup:$COWP443/"
        echo ""
      
		menu_number=0
        sleep 3s
        cd
    fi
	mailcow=n
}

installOwnCloud()
{
    app_name=$CFG_OWNCLOUD_APP_NAME
    host_name=$CFG_OWNCLOUD_HOST_NAME
    domain_number=$CFG_OWNCLOUD_DOMAIN_NUMBER
    public=$CFG_OWNCLOUD_PUBLIC
	port=$CFG_OWNCLOUD_PORT
	owncloud_version=$CFG_OWNCLOUD_VERSION

	if [[ "$owncloud" == *[uU]* ]]; then
		uninstallApp;
	fi

	if [[ "$owncloud" == *[sS]* ]]; then
		shutdownApp;
	fi

    if [[ "$owncloud" == *[rR]* ]]; then
        dockerDownUpDefault;
    fi

    if [[ "$owncloud" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###          Install $app_name"
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

		((menu_number++))
        echo ""
        echo "---- $menu_number. Setup .env file for $app_name"
        echo ""

if [[ "$public" == "true" ]]; then	
cd $install_path$app_name
sudo -u $easydockeruser cat << EOF > $install_path$app_name/.env
OWNCLOUD_VERSION=$owncloud_version
OWNCLOUD_DOMAIN=DOMAINSUBNAMEHERE:$port
OWNCLOUD_TRUSTED_DOMAINS=DOMAINSUBNAMEHERE
ADMIN_USERNAME=$CFG_OWNCLOUD_ADMIN_USERNAME
ADMIN_PASSWORD=$CFG_OWNCLOUD_ADMIN_PASSWORD
HTTP_PORT=$port
EOF
fi

if [[ "$public" == "false" ]]; then	
cd $install_path$app_name
sudo -u $easydockeruser cat << EOF > $install_path$app_name/.env
OWNCLOUD_VERSION=$owncloud_version
OWNCLOUD_DOMAIN=IPADDRESSHERE:$port
OWNCLOUD_TRUSTED_DOMAINS=IPADDRESSHERE
ADMIN_USERNAME=$CFG_OWNCLOUD_ADMIN_USERNAME
ADMIN_PASSWORD=$CFG_OWNCLOUD_ADMIN_PASSWORD
HTTP_PORT=$port
EOF
fi
		editEnvFileDefault;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		dockerDownUpDefault;

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
	owncloud=n
}

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

		result=$(sudo -u $easydockeruser git clone https://github.com/vsellier/easy-cozy.git $install_path/$app_name)
		checkSuccess "Cloning the Easy-Cozy from GitHub"
		
		result=$(sudo -u $easydockeruser cp $install_path/$app_name/env.template $install_path/$app_name/.env | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" 2>&1)
		checkSuccess "Coping .env template into .env for usage"

		result=$(sudo -u $easydockeruser sed -i "s|DATABASE_DIRECTORY=/var/lib/cozy/db|DATABASE_DIRECTORY=$install_path/$app_name/db|g" $install_path/$app_name/.env)
		checkSuccess "Update database directory to the correct install path"

		result=$(sudo -u $easydockeruser sed -i "s|STORAGE_DIRECTORY=/var/lib/cozy/storage/STORAGE_DIRECTORY=$install_path/$app_name/storage/g" $install_path/$app_name/.env)
		checkSuccess "Update storage directory to the correct install path"

		result=$(sudo -u $easydockeruser sed -i "s|ACME_DIRECTORY=/var/lib/acme|ACME_DIRECTORY=$install_path/$app_name/acme|g" $install_path/$app_name/.env)
		checkSuccess "Update acme directory to the correct install path"

		result=$(sudo -u $easydockeruser sed -i "s|COZY_TLD=cozy.mydomain.tld|COZY_TLD=cozy.$domain_full|g" $install_path/$app_name/.env)
		checkSuccess "Update the domain name to $domain_full"

		result=$(sudo -u $easydockeruser sed -i "s|EMAIL=bofh@mydomain.tld|EMAIL=$CFG_EMAIL|g" $install_path/$app_name/.env)
		checkSuccess "Update the email to $CFG_EMAIL"

		result=$(sudo -u $easydockeruser sed -i "s|COZY_ADMIN_PASSPHRASE=changeme|COZY_ADMIN_PASSPHRASE=$CFG_COZY_ADMIN_PASSPHRASE|g" $install_path/$app_name/.env)
		checkSuccess "Update the Admin Passphrase to the specified password in the apps config"
		
		result=$(mkdirFolders $install_path/$app_name/db $install_path/$app_name/storage)
		checkSuccess "Creating db and storage folders"

		setupComposeFileApp;

		result=$(sudo -u $easydockeruser sed -i '35,$ d' $install_path/$app_name/docker-compose.yml)
		checkSuccess "Removing line 35 from the docker-compose.yml file"

		result=$(sudo -u $easydockeruser sed -i "s|- \"traefik|  # - \"traefik|g" $install_path/$app_name/docker-compose.yml)
		checkSuccess "Disabling all outdated Traefik values in docker-compose.yml "

		result=$(sudo -u $easydockeruser sed -i "s|labels:|#labels:|g" $install_path/$app_name/docker-compose.yml)
		checkSuccess "Disabling labels in docker-compose.yml as we have custom values."

		editComposeFileApp;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		dockerDownUpDefault;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Setting up Users with their applications for $app_name"
        echo ""

		# Setting up a single instance of Cozy
		result=$(cd $install_path/$app_name && sudo -u $easydockeruser ./create-instance.sh $cozy_user_1)
		checkSuccess "Creating instance of $app_name for $cozy_user_1"

		if [[ "$cozy_user_1_apps_enabled" == true ]]; then
			result=$(sudo -u $easydockeruser ./application.sh $cozy_user_1 $cozy_user_1_apps)
			checkSuccess "Setting up applications for $app_name for $cozy_user_1"
		fi

		((menu_number++))
		echo ""
        echo "---- $menu_number. Adding $app_name to the Apps Database table."
        echo ""

		databaseInstallApp;

		((menu_number++))
        echo ""
        echo "---- $menu_number. You can find $app_name files at $install_path$app_name"
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

installTrilium()
{
    app_name=$CFG_TRILIUM_APP_NAME
    host_name=$CFG_TRILIUM_HOST_NAME
    domain_number=$CFG_TRILIUM_DOMAIN_NUMBER
    public=$CFG_TRILIUM_PUBLIC
	port=$CFG_TRILIUM_PORT

    if [[ "$trilium" == *[uU]* ]]; then
        uninstallApp;
    fi

    if [[ "$trilium" == *[sS]* ]]; then
        shutdownApp;
    fi

    if [[ "$trilium" == *[rR]* ]]; then
        dockerDownUpDefault;
    fi

    if [[ "$trilium" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###          Install $app_name"
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

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		dockerDownUpDefault;

		((menu_number++))
		echo ""
        echo "---- $menu_number. Adding $app_name to the Apps Database table."
        echo ""

		databaseInstallApp;

		((menu_number++))
        echo ""
        echo "---- $menu_number. You can find $app_name files at $install_path$app_name"
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
    trilium=n
}

installIPInfo()
{
    app_name=$CFG_IPINFO_APP_NAME
    host_name=$CFG_IPINFO_HOST_NAME
    domain_number=$CFG_IPINFO_DOMAIN_NUMBER
    public=$CFG_IPINFO_PUBLIC
	port=$CFG_IPINFO_PORT

	if [[ "$ipinfo" == *[uU]* ]]; then
		uninstallApp;
	fi

	if [[ "$ipinfo" == *[sS]* ]]; then
		shutdownApp;
	fi

	if [[ "$ipinfo" == *[rR]* ]]; then
		dockerDownUpDefault;
	fi

    if [[ "$ipinfo" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###           Install $app_name"
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

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		dockerDownUpDefault;

		((menu_number++))
		echo ""
        echo "---- $menu_number. Adding $app_name to the Apps Database table."
        echo ""

		databaseInstallApp;

		((menu_number++))
        echo ""
        echo "---- $menu_number. You can find $app_name files at $install_path$app_name"
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
    ipinfo=n
}

installSearXNG()
{
    app_name=$CFG_SEARXNG_APP_NAME
    host_name=$CFG_SEARXNG_HOST_NAME
    domain_number=$CFG_SEARXNG_DOMAIN_NUMBER
    public=$CFG_SEARXNG_PUBLIC
	port=$CFG_SEARXNG_PORT
	
	if [[ "$searxng" == *[uU]* ]]; then
		uninstallApp;
	fi

	if [[ "$searxng" == *[sS]* ]]; then
		shutdownApp;
	fi

	if [[ "$searxng" == *[rR]* ]]; then
		dockerDownUpDefault;
	fi

	if [[ "$searxng" == *[iI]* ]]; then
		echo ""
		echo "##########################################"
		echo "###          Install $app_name"
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

		((menu_number++))
        echo ""
		echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
		echo ""

		dockerDownUpDefault;

		# Loop to check for the existence of the file every second
		while [ ! -f "$install_path$app_name/searxng-data/settings.yml" ]; do
			isNotice "Waiting for the file to appear..."
			read -t 1 # Wait for 1 second
		done

		# Perform the required operation on the file once it exists
		result=$(sudo -u $easydockeruser sed -i "s/simple_style: auto/simple_style: dark/" "$install_path$app_name/searxng-data/settings.yml")
		checkSuccess "Changing from light mode to dark mode to avoid eye strain installs"

		dockerDownUpDefault;

		((menu_number++))
		echo ""
        echo "---- $menu_number. Adding $app_name to the Apps Database table."
        echo ""

		databaseInstallApp;

		((menu_number++))
        echo ""
        echo "---- $menu_number. You can find $app_name files at $install_path$app_name"
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
	searxng=n
}

installSpeedtest()
{
    app_name=$CFG_SPEEDTEST_APP_NAME
    host_name=$CFG_SPEEDTEST_HOST_NAME
    domain_number=$CFG_SPEEDTEST_DOMAIN_NUMBER
    public=$CFG_SPEEDTEST_PUBLIC
	port=$CFG_SPEEDTEST_PORT

	if [[ "$speedtest" == *[uU]* ]]; then
		uninstallApp;
	fi

	if [[ "$speedtest" == *[sS]* ]]; then
		shutdownApp;
	fi

	if [[ "$speedtest" == *[rR]* ]]; then
		dockerDownUpDefault;
	fi

    if [[ "$speedtest" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###           Install $app_name"
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

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		dockerDownUpDefault;

		((menu_number++))
		echo ""
        echo "---- $menu_number. Adding $app_name to the Apps Database table."
        echo ""

		databaseInstallApp;

		((menu_number++))
        echo ""
        echo "---- $menu_number. You can find $app_name files at $install_path$app_name"
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
	speedtest=n
}

installVaultwarden()
{
    app_name=$CFG_VAULTWARDEN_APP_NAME
    host_name=$CFG_VAULTWARDEN_HOST_NAME
    domain_number=$CFG_VAULTWARDEN_DOMAIN_NUMBER
    public=$CFG_VAULTWARDEN_PUBLIC
	port=$CFG_VAULTWARDEN_PORT

	if [[ "$vaultwarden" == *[uU]* ]]; then
		uninstallApp;
	fi

	if [[ "$vaultwarden" == *[sS]* ]]; then
		shutdownApp;
	fi

	if [[ "$vaultwarden" == *[rR]* ]]; then
		dockerDownUpDefault;
	fi

    if [[ "$vaultwarden" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###           Install $app_name"
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

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		dockerDownUpDefault;

		((menu_number++))
		echo ""
        echo "---- $menu_number. Adding $app_name to the Apps Database table."
        echo ""

		databaseInstallApp;

		((menu_number++))
        echo ""
        echo "---- $menu_number. You can find $app_name files at $install_path$app_name"
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
	vaultwarden=n
}

installActual()
{
    app_name=$CFG_ACTUAL_APP_NAME
    host_name=$CFG_ACTUAL_HOST_NAME
    domain_number=$CFG_ACTUAL_DOMAIN_NUMBER
    public=$CFG_ACTUAL_PUBLIC
	port=$CFG_ACTUAL_PORT

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

			result=$(sudo -u $easydockeruser mkdir -p $install_path$app_name/actual-data)
			checkSuccess "Create actual-data folder"
			
			result=$(sudo -u $easydockeruser cp $script_dir/resources/$app_name/config.json $install_path$app_name/actual-data/config.json | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" 2>&1)
			checkSuccess "Copying config.json to actual-data folder"

			result=$(sudo -u $easydockeruser cp $ssl_dir/$ssl_crt $install_path$app_name/actual-data/cert.pem | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" 2>&1)
			checkSuccess "Copying cert to actual-data folder"

			result=$(sudo -u $easydockeruser cp $ssl_dir/$ssl_key $install_path$app_name/actual-data/key.pem | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" 2>&1)
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