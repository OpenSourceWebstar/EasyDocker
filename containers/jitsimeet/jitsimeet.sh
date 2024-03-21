#!/bin/bash

# Category : user
# Description : Jitsi Meet - Video Conferencing (c/u/s/r/i):

installJitsimeet()
{
    if [[ "$jitsimeet" == *[cCtTuUsSrRiI]* ]]; then
    	dockerConfigSetupToContainer silent jitsimeet;
		local app_name=$CFG_JITSIMEET_APP_NAME
		git_url=$CFG_JITSIMEET_GIT
		setupInstallVariables $app_name;
	fi
    
    if [[ "$jitsimeet" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

	if [[ "$jitsimeet" == *[uU]* ]]; then
		dockerUninstallApp $app_name;
	fi

	if [[ "$jitsimeet" == *[sS]* ]]; then
		dockerComposeDown $app_name;
	fi

    if [[ "$jitsimeet" == *[rR]* ]]; then
        dockerComposeRestart $app_name;
    fi

    if [[ "$jitsimeet" == *[iI]* ]]; then
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

        portsCheckApp $app_name install;
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
        echo "---- $menu_number. Downloading latest GitHub release"
        echo ""

		latest_tag=$(git ls-remote --refs --sort="version:refname" --tags $git_url | cut -d/ -f3- | tail -n1)
		echo "The latest tag is: $latest_tag"

		local result=$(createFolders "loud" $CFG_DOCKER_INSTALL_USER $containers_dir$app_name)
		checkSuccess "Creating $app_name container installation folder"
		local result=$(cd $containers_dir$app_name && sudo rm -rf $containers_dir$app_name/$latest_tag.zip)
		checkSuccess "Deleting zip file to prevent conflicts"
		local result=$(createTouch $containers_dir$app_name/$latest_tag.txt $CFG_DOCKER_INSTALL_USER && echo 'Installed "$latest_tag" on "$backupDate"!' > $latest_tag.txt)
		checkSuccess "Create logging txt file"
		

		# Download files and unzip
		local result=$(sudo wget -O $containers_dir$app_name/$latest_tag.zip $git_url/archive/refs/tags/$latest_tag.zip)
		checkSuccess "Downloading tagged zip file from GitHub"
		local result=$(sudo unzip -o $containers_dir$app_name/$latest_tag.zip -d $containers_dir$app_name)
		checkSuccess "Unzip downloaded file"
		local result=$(sudo mv $containers_dir$app_name/docker-jitsi-meet-$latest_tag/* $containers_dir$app_name)
		checkSuccess "Moving all files from zip file to install directory"
		local result=$(sudo rm -rf $containers_dir$app_name/$latest_tag.zip && sudo rm -rf $containers_dir$app_name/$latest_tag/)
		checkSuccess "Removing downloaded zip file as no longer needed"
		
		((menu_number++))
        echo ""
        echo "---- $menu_number. Setting up the $app_name docker-compose.yml file."
        echo ""

        dockerComposeSetupFile $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Updating file permissions before starting."
        echo ""

		fixPermissionsBeforeStart $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Setting up .env file for setup"
        echo ""

		dockerSetupEnvFile;

		# Updating custom .env values
		local result=$(sudo sed -i "s|CONFIG=~/.jitsi-meet-cfg|CONFIG=$containers_dir$app_name/.jitsi-meet-cfg|g" $containers_dir$app_name/.env)
		checkSuccess "Updating .env file with new install path"

		local result=$(sudo sed -i "s|#PUBLIC_URL=https://meet.example.com|PUBLIC_URL=https://$host_setup|g" $containers_dir$app_name/.env)
		checkSuccess "Updating .env file with Public URL to $host_setup"

		local result=$(sudo sed -i "s|HTTP_PORT=8000|HTTP_PORT=$usedport1|g" $containers_dir$app_name/.env)
		checkSuccess "Updating .env file with HTTP_PORT to $usedport1"

		local result=$(sudo sed -i "s|HTTPS_PORT=8443|HTTPS_PORT=$usedport2|g" $containers_dir$app_name/.env)
		checkSuccess "Updating .env file with HTTP_PORT to $usedport2"

		#local result=$(echo "ENABLE_HTTP_REDIRECT=1" | sudo tee -a "$containers_dir$app_name/.env")
		#checkSuccess "Updating .env file with option : ENABLE_HTTP_REDIRECT"

		# Values are missing from the .env by default for some reason
		# https://github.com/jitsi/docker-jitsi-meet/commit/12051700562d9826f9e024ad649c4dd9b88f94de#diff-b335630551682c19a781afebcf4d07bf978fb1f8ac04c6bf87428ed5106870f5
		local result=$(echo "XMPP_DOMAIN=meet.jitsi" | sudo tee -a "$containers_dir$app_name/.env")
		checkSuccess "Updating .env file with missing option : XMPP_DOMAIN"

		local result=$(echo "XMPP_SERVER=xmpp.meet.jitsi" | sudo tee -a "$containers_dir$app_name/.env")
		checkSuccess "Updating .env file with missing option : XMPP_SERVER"

		local result=$(echo "JVB_PORT=$usedport4" | sudo tee -a "$containers_dir$app_name/.env")
		checkSuccess "Updating .env file with missing option : JVB_PORT"

		local result=$(echo "JVB_TCP_MAPPED_PORT=$usedport5" | sudo tee -a "$containers_dir$app_name/.env")
		checkSuccess "Updating .env file with missing option : JVB_TCP_MAPPED_PORT"

		local result=$(echo "JVB_TCP_PORT=$usedport5" | sudo tee -a "$containers_dir$app_name/.env")
		checkSuccess "Updating .env file with missing option : JVB_TCP_PORT"

		local result=$(cd "$containers_dir$app_name" && sudo ./gen-passwords.sh)
		checkSuccess "Running Jitsi Meet gen-passwords.sh script"

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		dockerComposeUpdateAndStartApp $app_name install;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Adjusting $app_name docker system files for port changes."
        echo ""

        #dockerCommandRun "docker exec -it $app_name /bin/bash && cd /"

		#local result=$(sudo sed -i "s|80|$usedport1|g" $containers_dir$app_nameweb/default)
		#checkSuccess "Updating Docker NGINX default site port 80 to $usedport1"

		#local result=$(sudo sed -i "s|443|$usedport2|g" $containers_dir$app_nameweb/default)
		#checkSuccess "Updating Docker NGINX default site port 443 to $usedport2"

		local result=$(sudo sed -i "s|80|$usedport1|g" $containers_dir$app_name/web/rootfs/defaults/default)
		checkSuccess "Updating NGINX default site port 80 to $usedport1"

		local result=$(sudo sed -i "s|443|$usedport2|g" $containers_dir$app_name/web/rootfs/defaults/default)
		checkSuccess "Updating NGINX default site port 443 to $usedport2"

        #dockerCommandRun "docker cp '$containers_dir$app_name' '$app_name:/etc/nginx/sites-available/default'"
		dockerComposeRestart $app_name;

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Running Application specific updates (if required)"
        echo ""

        appUpdateSpecifics $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running Headscale setup (if required)"
        echo ""

		setupHeadscale $app_name;
		
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
		
        menuShowFinalMessages $app_name;
		    
		menu_number=0
        sleep 3s
        cd
	fi
	jitsimeet=n
}