#!/bin/bash

# Category : user
# Description : Mattermost - Collaboration Platform (c/u/s/r/i):

installMattermost()
{
    if [[ "$mattermost" == *[cCtTuUsSrRiI]* ]]; then
    	setupConfigToContainer mattermost;
		local app_name=$CFG_MATTERMOST_APP_NAME
		easy_setup=$CFG_MATTERMOST_EASY_SETUP
		setupInstallVariables $app_name;
	fi

    if [[ "$mattermost" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

	if [[ "$mattermost" == *[uU]* ]]; then
		uninstallApp $app_name;
	fi

	if [[ "$mattermost" == *[sS]* ]]; then
		shutdownApp $app_name;
	fi

	if [[ "$mattermost" == *[rR]* ]]; then
        dockerDownUp $app_name;
	fi

    if [[ "$mattermost" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###        Install $app_name"
        echo "##########################################"
        echo ""

		((menu_number++))
        echo ""
        echo "---- $menu_number. Setting up install folder and config file for $app_name."
        echo ""

        setupConfigToContainer $app_name install;
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
        echo "---- $menu_number. Pulling Mattermost GitHub repo"
        echo ""

        local result=$(mkdirFolders $containers_dir$app_name)
		checkSuccess "Creating $app_name install folder"

        local result=$(sudo -u $easydockeruser git clone https://github.com/mattermost/docker $containers_dir$app_name)
		checkSuccess "Cloning Mattermost GitHub"

        local result=$(copyFile $containers_dir$app_name/env.example $containers_dir$app_name/.env)
		checkSuccess "Copying example .env file for setup"

        local result=$(mkdirFolders $containers_dir$app_name/volumes/app/mattermost/{config,data,logs,plugins,client/plugins,bleve-indexes})
		checkSuccess "Creating folders needed for $app_name"

        local result=$(sudo chown -R 2000:2000 $containers_dir$app_name/volumes/app/mattermost)
		checkSuccess "Setting folder permissions for $app_name folders"

        local result=$(sudo sed -i "s/DOMAIN=mm.example.com/DOMAIN=$host_setup/g" $containers_dir$app_name/.env)
		checkSuccess "Updating .env file with Domain $host_setup"	
		
        local result=$(sudo sed -i 's/HTTP_PORT=80/HTTP_PORT='$usedport1'/' $containers_dir$app_name/.env)
		checkSuccess "Updating .env file HTTP_PORT to $usedport1"	
				
        local result=$(sudo sed -i 's/HTTPS_PORT=443/HTTPS_PORT='$usedport2'/' $containers_dir$app_name/.env)
		checkSuccess "Updating .env file HTTPS_PORT to $usedport2"	
		
		editEnvFileDefault;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Updating file permissions before starting."
        echo ""

		fixPermissionsBeforeStart $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start Mattermost"
        echo ""

mattermostAddToYMLFile() 
{
  local file_path="$1"
  sudo tee -a "$file_path" <<EOF
    labels:
      traefik.enable: true
      traefik.http.routers.mattermost.entrypoints: web,websecure
      traefik.http.routers.mattermost.rule: Host(\`DOMAINSUBNAMEHERE\`)
      traefik.http.routers.mattermost.tls: true
      traefik.http.routers.mattermost.tls.certresolver: production
    networks:
      vpn:
        ipv4_address: IPADDRESSHERE

  postgres:
    networks:
      vpn:
        ipv4_address: 10.8.1.105

  networks:
    vpn:
      external: true
EOF
}

		local DCN=docker-compose.nginx.yml
		local DCWN=docker-compose.without-nginx.yml

		isQuestion "Do you already have a Reverse Proxy installed? (y/n): "
		read -rp "" MATN
    	if [[ "$MATN" == [nN] ]]; then
			if [[ "$OS" == [1234567] ]]; then
				if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
					local result=$(runCommandForDockerInstallUser "cd $containers_dir$app_name && docker-compose -f docker-compose.yml -f $DCWN down")
					checkSuccess "Shutting down nginx container"

					local result=$(runCommandForDockerInstallUser "cd $containers_dir$app_name && docker-compose -f docker-compose.yml -f $DCN up -d")
					checkSuccess "Starting up nginx container"
				elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
					local result=$(cd $containers_dir$app_name && sudo -u $easydockeruser docker-compose -f docker-compose.yml -f $DCWN down)
					checkSuccess "Shutting down nginx container"

					local result=$(cd $containers_dir$app_name && sudo -u $easydockeruser docker-compose -f docker-compose.yml -f $DCN up -d)
					checkSuccess "Starting up nginx container"
				fi
			fi
		fi

		if [[ "$MATN" == [yY] ]]; then
			if [[ "$OS" == [1234567] ]]; then
				if grep -q "vpn:" $containers_dir$app_name/$DCWN; then
					isError "The Compose file already contains custom edits. Please reinstalled $app_name"
				else			
					removeEmptyLineAtFileEnd "$containers_dir$app_name/$DCWN"
					mattermostAddToYMLFile "$containers_dir$app_name/$DCWN"
					editCustomFile "$containers_dir$app_name" "$DCWN"
				fi
				 
				if [ -f "docker-compose.yml" ] && [ -f "$DCWN" ]; then
					if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
						local result=$(runCommandForDockerInstallUser "cd $containers_dir$app_name && docker-compose -f docker-compose.yml -f $DCWN down")
						checkSuccess "Shutting down container for $app_name - (Without Nginx Compose File)"

            			isNotice "Starting container for $app_name, this may take a while..."
						local result=$(runCommandForDockerInstallUser "cd $containers_dir$app_name && docker-compose -f docker-compose.yml -f $DCWN up -d")
						checkSuccess "Started container for $app_name - (Without Nginx Compose File)"
					elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
						local result=$(cd $containers_dir$app_name && sudo -u $easydockeruser docker-compose -f docker-compose.yml -f $DCWN down)
						checkSuccess "Shutting down container for $app_name - (Without Nginx Compose File)"
						
            			isNotice "Starting container for $app_name, this may take a while..."
						local result=$(cd $containers_dir$app_name && sudo -u $easydockeruser docker-compose -f docker-compose.yml -f $DCWN up -d)
						checkSuccess "Started container for $app_name - (Without Nginx Compose File)"
					fi
				fi
			fi
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
        echo "    You can now navigate to your new service using one of the options below : "
        echo ""
        echo "    Public : https://$host_setup/"
        echo "    External : http://$public_ip:$usedport1/"
        echo "    Local : http://$ip_setup:$usedport1/"
        echo ""

		menu_number=0
        sleep 3s
        cd
	fi

	mattermost=n
}