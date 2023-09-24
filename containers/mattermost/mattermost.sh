#!/bin/bash

# Category : user
# Description : Mattermost - Collaboration Platform (c/u/s/r/i):

installMattermost()
{
    setupConfigToContainer mattermost;

    if [[ "$mattermost" =~ [a-zA-Z] ]]; then
		app_name=$CFG_MATTERMOST_APP_NAME
		easy_setup=$CFG_MATTERMOST_EASY_SETUP
	fi

    if [[ "$mattermost" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

	if [[ "$mattermost" == *[uU]* ]]; then
		uninstallApp $app_name;
	fi

	if [[ "$mattermost" == *[sS]* ]]; then
		shutdownApp;
	fi

	if [[ "$mattermost" == *[rR]* ]]; then
		setupInstallVariables $app_name;
        if [[ $compose_setup == "default" ]]; then
		    dockerDownUpDefault $app_name;
        elif [[ $compose_setup == "app" ]]; then
            dockerDownUpAdditionalYML $app_name;
        fi
	fi

    if [[ "$mattermost" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###        Install $app_name"
        echo "##########################################"
        echo ""

		((menu_number++))
        echo ""
        echo "---- $menu_number. Checking custom DNS entry and IP for setup"
        echo ""

		setupInstallVariables $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Setting up Ports for $app_name"
        echo ""
		
		if [[ "$easy_setup" == "true" ]]; then
			MATP80C=8011
			MATP443C=4431
		else
			read -rp "Do you want to change the custom HTTP port 8011 for Mattermost? (y/n): " MATP80_PROMPT
			if [[ "$MATP80_PROMPT" == [yY] ]]; then
				while true; do
					read -rp "Enter the port you want to use instead of 80 (#): " MATP80C
					if [[ $MATP80C =~ ^[0-9]+$ ]]; then
						echo "Given valid port $MATP80C"
						break
					else
						echo "Ports should only contain numbers, please try again."
					fi
				done
			else
				MATP80C=8011
			fi

			read -rp "Do you want to change the custom HTTPS port 4431 for Mattermost? (y/n): " MATP443_PROMPT
			if [[ "$MATP443_PROMPT" == [yY] ]]; then
				while true; do
					read -rp "Enter the port you want to use instead of 443 (#): " MATP443C
					if [[ $MATP443C =~ ^[0-9]+$ ]]; then
						echo "Given valid port $MATP443C"
						break
					else
						echo "Ports should only contain numbers, please try again."
					fi
				done
			else
				MATP443C=4431
			fi
		fi
	
		((menu_number++))
        echo ""
        echo "---- $menu_number. Pulling Mattermost GitHub repo"
        echo ""

        result=$(mkdirFolders $install_dir$app_name)
		checkSuccess "Creating $app_name install folder"

        result=$(sudo -u $easydockeruser git clone https://github.com/mattermost/docker $install_dir$app_name)
		checkSuccess "Cloning Mattermost GitHub"

        result=$(copyFile $install_dir$app_name/env.example $install_dir$app_name/.env)
		checkSuccess "Copying example .env file for setup"

        result=$(mkdirFolders $install_dir$app_name/volumes/app/mattermost/{config,data,logs,plugins,client/plugins,bleve-indexes})
		checkSuccess "Creating folders needed for $app_name"

        result=$(sudo chown -R 2000:2000 $install_dir$app_name/volumes/app/mattermost)
		checkSuccess "Setting folder permissions for $app_name folders"

        result=$(sudo sed -i "s/DOMAIN=mm.example.com/DOMAIN=$host_setup/g" $install_dir$app_name/.env)
		checkSuccess "Updating .env file with Domain $host_setup"	
		
        result=$(sudo sed -i 's/HTTP_PORT=80/HTTP_PORT='$MATP80C'/' $install_dir$app_name/.env)
		checkSuccess "Updating .env file HTTP_PORT to $MATP80C"	
				
        result=$(sudo sed -i 's/HTTPS_PORT=443/HTTPS_PORT='$MATP443C'/' $install_dir$app_name/.env)
		checkSuccess "Updating .env file HTTPS_PORT to $MATP443C"	
		
		editEnvFileDefault;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Updating file permissions before starting."
        echo ""

		fixPermissionsBeforeStart;

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
      traefik.http.routers.mattermost.rule: Host(\`DOMAINSUBNAMEHERE\`) # Update to your domain
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

		DCN=docker-compose.nginx.yml
		DCWN=docker-compose.without-nginx.yml

		isQuestion "Do you already have a Reverse Proxy installed? (y/n): "
		read -rp "" MATN
    	if [[ "$MATN" == [nN] ]]; then
			if [[ "$OS" == [123] ]]; then
				if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
					result=$(runCommandForDockerInstallUser "cd $install_dir$app_name && docker-compose -f docker-compose.yml -f $DCWN down")
					checkSuccess "Shutting down nginx container"

					result=$(runCommandForDockerInstallUser "cd $install_dir$app_name && docker-compose -f docker-compose.yml -f $DCN up -d")
					checkSuccess "Starting up nginx container"
				elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
					result=$(cd $install_dir$app_name && sudo -u $easydockeruser docker-compose -f docker-compose.yml -f $DCWN down)
					checkSuccess "Shutting down nginx container"

					result=$(cd $install_dir$app_name && sudo -u $easydockeruser docker-compose -f docker-compose.yml -f $DCN up -d)
					checkSuccess "Starting up nginx container"
				fi
			fi
		fi

		if [[ "$MATN" == [yY] ]]; then
			if [[ "$OS" == [123] ]]; then
				if grep -q "vpn:" $install_dir$app_name/$DCWN; then
					isError "The Compose file already contains custom edits. Please reinstalled $app_name"
				else			
					removeEmptyLineAtFileEnd "$install_dir$app_name/$DCWN"
					mattermostAddToYMLFile "$install_dir$app_name/$DCWN"
					editCustomFile "$install_dir$app_name" "$DCWN"
				fi

				 
				if [ -f "docker-compose.yml" ] && [ -f "$DCWN" ]; then
					if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
						result=$(runCommandForDockerInstallUser "cd $install_dir$app_name && docker-compose -f docker-compose.yml -f $DCWN down")
						checkSuccess "Shutting down container for $app_name - (Without Nginx Compose File)"

						result=$(runCommandForDockerInstallUser "cd $install_dir$app_name && docker-compose -f docker-compose.yml -f $DCWN up -d")
						checkSuccess "Starting up container for $app_name - (Without Nginx Compose File)"
					elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
						result=$(cd $install_dir$app_name && sudo -u $easydockeruser docker-compose -f docker-compose.yml -f $DCWN down)
						checkSuccess "Shutting down container for $app_name - (Without Nginx Compose File)"
						
						result=$(cd $install_dir$app_name && sudo -u $easydockeruser docker-compose -f docker-compose.yml -f $DCWN up -d)
						checkSuccess "Starting up container for $app_name - (Without Nginx Compose File)"
					fi
				fi
			fi
		fi

		((menu_number++))
		echo ""
        echo "---- $menu_number. Adding $app_name to the Apps Database table."
        echo ""

		databaseInstallApp;

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Opening ports if required"
        echo ""

        openAppPorts $app_name;

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

	mattermost=n
}