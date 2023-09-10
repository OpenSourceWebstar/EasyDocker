#!/bin/bash

app_name="$1"

installTileDesk()
{
    app_name=$CFG_TILEDESK_APP_NAME
    host_name=$CFG_TILEDESK_HOST_NAME
    domain_number=$CFG_TILEDESK_DOMAIN_NUMBER
    public=$CFG_TILEDESK_PUBLIC
	port=$CFG_TILEDESK_PORT

	if [[ "$tiledesk" == *[uU]* ]]; then
		uninstallApp;
	fi

	if [[ "$tiledesk" == *[sS]* ]]; then
		shutdownApp;
	fi

    if [[ "$tiledesk" == *[rR]* ]]; then
        dockerDownUpDefault;
    fi

    if [[ "$tiledesk" == *[iI]* ]]; then
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

		setupComposeFileApp;

		result=$(cd $install_path$app_name && curl https://raw.githubusercontent.com/Tiledesk/tiledesk-deployment/master/docker-compose/docker-compose.yml --output docker-compose.yml)
		checkSuccess "Downloading docker-compose.yml from $app_name GitHub"		

		editComposeFileApp;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		if [[ "$OS" == [123] ]]; then
			if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
				result=$(runCommandForDockerInstallUser "docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml down")
				checkSuccess "Shutting down docker-compose.$app_name.yml"
				if [[ "$public" == "true" ]]; then
					result=$(runCommandForDockerInstallUser "EXTERNAL_BASE_URL="https://$domain_full" EXTERNAL_MQTT_BASE_URL="wss://$domain_full" docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml up -d")
					checkSuccess "Starting public docker-compose.$app_name.yml"
				else
					result=$(runCommandForDockerInstallUser "docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml up -d")
					checkSuccess "Starting standard docker-compose.$app_name.yml"
				fi
			elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
				result=$(sudo -u $easydockeruser docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml down)
				checkSuccess "Shutting down docker-compose.$app_name.yml"
				if [[ "$public" == "true" ]]; then
					result=$(EXTERNAL_BASE_URL="https://$domain_full" EXTERNAL_MQTT_BASE_URL="wss://$domain_full" sudo -u $easydockeruser docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml up -d)
					checkSuccess "Starting public docker-compose.$app_name.yml"
				else
					result=$(sudo -u $easydockeruser docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml up -d)
					checkSuccess "Starting standard docker-compose.$app_name.yml"
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
	tiledesk=n
}

installGitLab()
{
    app_name=$CFG_GITLAB_APP_NAME
    host_name=$CFG_GITLAB_HOST_NAME
    domain_number=$CFG_GITLAB_DOMAIN_NUMBER
    public=$CFG_GITLAB_PUBLIC
	port=$CFG_GITLAB_PORT
	port_2=$CFG_GITLAB_PORT_2

	if [[ "$gitlab" == *[uU]* ]]; then
		uninstallApp;
	fi

	if [[ "$gitlab" == *[sS]* ]]; then
		shutdownApp;
	fi

    if [[ "$gitlab" == *[rR]* ]]; then
        dockerDownUpDefault;
    fi

    if [[ "$gitlab" == *[iI]* ]]; then
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
        echo "    You can now navigate to your $app_name service using one of the options below : "
        echo ""
        echo "    Public : https://$host_setup/"
        echo "    External : http://$public_ip:$port/"
        echo "    Local : http://$ip_setup:$port/"
        echo ""
		      
		menu_number=0
        sleep 3s
        cd
	fi
	gitlab=n
}

installJitsiMeet()
{
    app_name=$CFG_JITSIMEET_APP_NAME
    host_name=$CFG_JITSIMEET_HOST_NAME
    domain_number=$CFG_JITSIMEET_DOMAIN_NUMBER
    public=$CFG_JITSIMEET_PUBLIC
	git_url=$CFG_JITSIMEET_GIT

	if [[ "$jitsimeet" == *[uU]* ]]; then
		uninstallApp;
	fi

	if [[ "$jitsimeet" == *[sS]* ]]; then
		shutdownApp;
	fi

    if [[ "$jitsimeet" == *[rR]* ]]; then
        dockerDownUpDefault;
    fi

    if [[ "$jitsimeet" == *[iI]* ]]; then
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
        echo "---- $menu_number. Downloading latest GitHub release"
        echo ""

		latest_tag=$(git ls-remote --refs --sort="version:refname" --tags $git_url | cut -d/ -f3- | tail -n1)
		echo "The latest tag is: $latest_tag"

		result=$(sudo -u $easydockeruser mkdir $install_path$app_name && cd $install_path$app_name)
		checkSuccess "Creating $app_name container installation folder"
		result=$(sudo -u $easydockeruser rm -rf $install_path$app_name/$latest_tag.zip)
		checkSuccess "Deleting zip file to prevent conflicts"
		result=$(createTouch $latest_tag.txt && echo 'Installed "$latest_tag" on "$backupDate"!' > $latest_tag.txt)
		checkSuccess "Create logging txt file"
		

		# Download files and unzip
		result=$(sudo -u $easydockeruser wget -O $install_path$app_name/$latest_tag.zip $git_url/archive/refs/tags/$latest_tag.zip)
		checkSuccess "Downloading tagged zip file from GitHub"
		result=$(sudo -u $easydockeruser unzip -o $install_path$app_name/$latest_tag.zip -d $install_path$app_name)
		checkSuccess "Unzip downloaded file"
		result=$(sudo -u $easydockeruser mv $install_path$app_name/docker-jitsi-meet-$latest_tag/* $install_path$app_name)
		checkSuccess "Moving all files from zip file to install directory"
		result=$(sudo -u $easydockeruser rm -rf $install_path$app_name/$latest_tag.zip && sudo -u $easydockeruser rm -rf $install_path$app_name/$latest_tag/)
		checkSuccess "Removing downloaded zip file as no longer needed"
		
		((menu_number++))
        echo ""
        echo "---- $menu_number. Pulling a default $app_name docker-compose.yml file."
        echo ""

		setupComposeFileNoApp;
		editComposeFileDefault;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Setting up .env file for setup"
        echo ""

		setupEnvFile;

		# Updating custom .env values
		result=$(sudo sed -i "s|CONFIG=~/.jitsi-meet-cfg|CONFIG=$install_path$app_name/.jitsi-meet-cfg|g" $install_path$app_name/.env)
		checkSuccess "Updating .env file with new install path"

		result=$(sudo sed -i "s|#PUBLIC_URL=https://meet.example.com|PUBLIC_URL=https://$host_setup|g" $install_path$app_name/.env)
		checkSuccess "Updating .env file with Public URL to $host_setup"

		# Values are missing from the .env by default for some reason
		# https://github.com/jitsi/docker-jitsi-meet/commit/12051700562d9826f9e024ad649c4dd9b88f94de#diff-b335630551682c19a781afebcf4d07bf978fb1f8ac04c6bf87428ed5106870f5
		result=$(echo "XMPP_DOMAIN=meet.jitsi" | sudo -u $easydockeruser tee -a "$install_path$app_name/.env")
		checkSuccess "Updating .env file with missing option : XMPP_DOMAIN"

		result=$(echo "XMPP_SERVER=xmpp.meet.jitsi" | sudo -u $easydockeruser tee -a "$install_path$app_name/.env")
		checkSuccess "Updating .env file with missing option : XMPP_SERVER"

		result=$(echo "JVB_PORT=10000" | sudo -u $easydockeruser tee -a "$install_path$app_name/.env")
		checkSuccess "Updating .env file with missing option : JVB_PORT"

		result=$(echo "JVB_TCP_MAPPED_PORT=4443" | sudo -u $easydockeruser tee -a "$install_path$app_name/.env")
		checkSuccess "Updating .env file with missing option : JVB_TCP_MAPPED_PORT"

		result=$(echo "JVB_TCP_PORT=4443" | sudo -u $easydockeruser tee -a "$install_path$app_name/.env")
		checkSuccess "Updating .env file with missing option : JVB_TCP_PORT"

		result=$(cd "$install_path$app_name" && sudo -u $easydockeruser ./gen-passwords.sh)
		checkSuccess "Running Jitsi Meet gen-passwords.sh script"

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		dockerDownUpDefault;

		((menu_number++))
		echo ""
        echo "---- $menu_number. Allowing $app_name through the UFW Firewall"
		echo ""

        result=$(sudo -u $easydockeruser ufw-docker allow jitsimeet-jvb-1 10000/udp)
		checkSuccess "Opening port 10000 for jitsimeet-jvb-1 with ufw-docker"

        result=$(sudo -u $easydockeruser ufw-docker allow jitsimeet-jvb-1 4443)
		checkSuccess "Opening port 4443 for jitsimeet-jvb-1 with ufw-docker"		

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
	jitsimeet=n
}

installKillbill()
{
    app_name=$CFG_KILLBILL_APP_NAME
    host_name=$CFG_KILLBILL_HOST_NAME
    domain_number=$CFG_KILLBILL_DOMAIN_NUMBER
    public=$CFG_KILLBILL_PUBLIC
	port=$CFG_KILLBILL_PORT

	if [[ "$killbill" == *[uU]* ]]; then
		uninstallApp;
	fi

	if [[ "$killbill" == *[sS]* ]]; then
		shutdownApp;
	fi

    if [[ "$killbill" == *[rR]* ]]; then
        dockerDownUpDefault;
    fi

    if [[ "$killbill" == *[iI]* ]]; then
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
	killbill=n
}

installAkaunting()
{
    app_name=$CFG_AKAUNTING_APP_NAME
    host_name=$CFG_AKAUNTING_HOST_NAME
    domain_number=$CFG_AKAUNTING_DOMAIN_NUMBER
    public=$CFG_AKAUNTING_PUBLIC
	port=$CFG_AKAUNTING_PORT

	if [[ "$akaunting" == *[uU]* ]]; then
		uninstallApp;
	fi

	if [[ "$akaunting" == *[sS]* ]]; then
		shutdownApp;
	fi

    if [[ "$akaunting" == *[rR]* ]]; then
        dockerDownUpDefault;
    fi

    if [[ "$akaunting" == *[iI]* ]]; then
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
        echo "---- $menu_number. Pulling a default Akaunting docker-compose.yml file and making edits."
        echo ""
		
		result=$(cd $install_path && sudo -u $easydockeruser git clone https://github.com/akaunting/docker $install_path$app_name)
		checkSuccess "Cloning the Akaunting GitHub repo"

		setupComposeFileApp;

		result=$(sudo sed -i 's|- akaunting-data:/var/www/html|- ./akaunting-data/:/var/www/html|g' $install_path$app_name/docker-compose.yml)
		checkSuccess "Updating akaunting-data to persistant storage"

		result=$(sudo sed -i 's|- akaunting-db:/var/lib/mysql|- ./akaunting-db/:/var/lib/mysql|g' $install_path$app_name/docker-compose.yml)
		checkSuccess "Updating akaunting-db to persistant storage"

		result=$(sudo sed -i "s|8080|$port|g" $install_path$app_name/docker-compose.yml)
		checkSuccess "Updating port 8080 to $port in docker-compose.yml"
		
		# Find the last instance of "networks:" in the file and get its line number
		last_network=$(sudo -u $easydockeruser grep -n 'networks:' "$install_path$app_name/docker-compose.yml" | cut -d: -f1 | tail -n 1)
		if [ -n "$last_network" ]; then
			result=$(sudo sed -i "${last_network},${last_network}+2s/^/# /" "$install_path$app_name/docker-compose.yml")
			checkSuccess "Comment out the last 'networks:' and the 2 lines below it."
		fi
		
		editComposeFileApp;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Setting up .env files."
        echo ""

		result=$(copyFile $install_path$app_name/env/db.env.example $install_path$app_name/env/db.env)
		checkSuccess "Copying example db.env for setup"

		result=$(copyFile $install_path$app_name/env/run.env.example $install_path$app_name/env/run.env)
		checkSuccess "Copying example run.env for setup"
	
		result=$(sudo sed -i "s/akaunting.example.com/$host_setup/g" $install_path$app_name/env/run.env)
		checkSuccess "Updating Domain in run.env to $host_setup"
		
		result=$(sudo sed -i "s/en-US/$CFG_AKAUNTING_LANGUAGE/g" $install_path$app_name/env/run.env)
		checkSuccess "Updating language in run.env to $CFG_AKAUNTING_LANGUAGE"	

		result=$(sudo sed -i "s/akaunting_password/$CFG_AKAUNTING_PASSWORD/g" $install_path$app_name/env/db.env)
		checkSuccess "Setting Akaunting Password to generated password in config file"

        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start Akaunting"
        echo ""

		# Check if this is a first time setup
		if [ -f "$install_path$app_name/SETUPINITIALIZED" ]; then
			isNotice "Running setup as initial setup file not found."

			result=$(createTouch $install_path$app_name/SETUPINITIALIZED)
			checkSuccess "Creating initizilation file"

			if [[ "$OS" == [123] ]]; then
				if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
					result=$(runCommandForDockerInstallUser "cd $install_path$app_name && AKAUNTING_SETUP=true docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml up -d)")
					isSuccessful "Starting $app_name up with initial setup flag"
				elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
					result=$(cd $install_path$app_name && AKAUNTING_SETUP=true sudo -u $easydockeruser docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml up -d)
					isSuccessful "Starting $app_name up with initial setup flag"
				fi
			fi
		else
			isNotice "It seems $app_name is already setup, using the normal up command"
			dockerUpDownAdditionalYML;
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
	akaunting=n
}

installKimai()
{
    app_name=$CFG_KIMAI_APP_NAME
    host_name=$CFG_KIMAI_HOST_NAME
    domain_number=$CFG_KIMAI_DOMAIN_NUMBER
    public=$CFG_KIMAI_PUBLIC
	port=$CFG_KIMAI_PORT

	if [[ "$kimai" == *[uU]* ]]; then
		uninstallApp;
	fi

	if [[ "$kimai" == *[sS]* ]]; then
		shutdownApp;
	fi

    if [[ "$kimai" == *[rR]* ]]; then
        dockerDownUpDefault;
    fi

    if [[ "$kimai" == *[iI]* ]]; then
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
        echo "---- $menu_number. Pulling a default Kimai docker-compose.yml file."
        echo ""

		setupComposeFileNoApp;
		editComposeFileDefault;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start Kimai"
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
	kimai=n
}

installMattermost()
{
    app_name=$CFG_MATTERMOST_APP_NAME
    host_name=$CFG_MATTERMOST_HOST_NAME
    domain_number=$CFG_MATTERMOST_DOMAIN_NUMBER
    public=$CFG_MATTERMOST_PUBLIC
	port=$CFG_MATTERMOST_PORT
	easy_setup=$CFG_MATTERMOST_EASY_SETUP

	if [[ "$mattermost" == *[uU]* ]]; then
		uninstallApp;
	fi

	if [[ "$mattermost" == *[sS]* ]]; then
		shutdownApp;
	fi

	if [[ "$mattermost" == *[rR]* ]]; then
		dockerDownUpDefault;
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

		setupIPsAndHostnames;

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

        result=$(mkdirFolders $install_path$app_name)
		checkSuccess "Creating $app_name install folder"

        result=$(sudo -u $easydockeruser git clone https://github.com/mattermost/docker $install_path$app_name)
		checkSuccess "Cloning Mattermost GitHub"

        result=$(copyFile $install_path$app_name/env.example $install_path$app_name/.env)
		checkSuccess "Copying example .env file for setup"

        result=$(mkdirFolders $install_path$app_name/volumes/app/mattermost/{config,data,logs,plugins,client/plugins,bleve-indexes})
		checkSuccess "Creating folders needed for $app_name"

        result=$(sudo -u $easydockeruser chown -R 2000:2000 $install_path$app_name/volumes/app/mattermost)
		checkSuccess "Setting folder permissions for $app_name folders"

        result=$(sudo sed -i "s/DOMAIN=mm.example.com/DOMAIN=$host_setup/g" $install_path$app_name/.env)
		checkSuccess "Updating .env file with Domain $host_setup"	
		
        result=$(sudo sed -i 's/HTTP_PORT=80/HTTP_PORT='$MATP80C'/' $install_path$app_name/.env)
		checkSuccess "Updating .env file HTTP_PORT to $MATP80C"	
				
        result=$(sudo sed -i 's/HTTPS_PORT=443/HTTPS_PORT='$MATP443C'/' $install_path$app_name/.env)
		checkSuccess "Updating .env file HTTPS_PORT to $MATP443C"	
		
		editEnvFileDefault;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start Mattermost"
        echo ""

mattermostAddToYMLFile() 
{
  local file_path="$1"
  sudo -u $easydockeruser tee -a "$file_path" <<EOF
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
					result=$(runCommandForDockerInstallUser "docker-compose -f docker-compose.yml -f $DCWN down")
					checkSuccess "Shutting down nginx container"

					result=$(runCommandForDockerInstallUser "docker-compose -f docker-compose.yml -f $DCN up -d")
					checkSuccess "Starting up nginx container"
				elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
					result=$(sudo -u $easydockeruser docker-compose -f docker-compose.yml -f $DCWN down)
					checkSuccess "Shutting down nginx container"

					result=$(sudo -u $easydockeruser docker-compose -f docker-compose.yml -f $DCN up -d)
					checkSuccess "Starting up nginx container"
				fi
			fi
		fi

		if [[ "$MATN" == [yY] ]]; then
			if [[ "$OS" == [123] ]]; then
				if grep -q "vpn:" $install_path$app_name/$DCWN; then
					isError "The Compose file already contains custom edits. Please reinstalled $app_name"
				else			
					removeEmptyLineAtFileEnd "$install_path$app_name/$DCWN"
					mattermostAddToYMLFile "$install_path$app_name/$DCWN"
					editCustomFile "$install_path$app_name" "$DCWN"
				fi

				cd $install_path$app_name 
				if [ -f "docker-compose.yml" ] && [ -f "$DCWN" ]; then
					if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
						result=$(runCommandForDockerInstallUser "docker-compose -f docker-compose.yml -f $DCWN down")
						checkSuccess "Shutting down container for $app_name - (Without Nginx Compose File)"

						result=$(runCommandForDockerInstallUser "docker-compose -f docker-compose.yml -f $DCWN up -d")
						checkSuccess "Starting up container for $app_name - (Without Nginx Compose File)"
					elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
						result=$(sudo -u $easydockeruser docker-compose -f docker-compose.yml -f $DCWN down)
						checkSuccess "Shutting down container for $app_name - (Without Nginx Compose File)"
						
						result=$(sudo -u $easydockeruser docker-compose -f docker-compose.yml -f $DCWN up -d)
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

	mattermost=n
}