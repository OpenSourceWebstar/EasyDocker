#!/bin/bash

# Category : user
# Description : Jitsi Meet - Video Conferencing (c/u/s/r/i):

installJitsimeet()
{
    if [[ "$jitsimeet" == *[cCtTuUsSrRiI]* ]]; then
    	setupConfigToContainer jitsimeet;
		local app_name=$CFG_JITSIMEET_APP_NAME
		git_url=$CFG_JITSIMEET_GIT
		setupInstallVariables $app_name;
	fi
    
    if [[ "$jitsimeet" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

	if [[ "$jitsimeet" == *[uU]* ]]; then
		uninstallApp $app_name;
	fi

	if [[ "$jitsimeet" == *[sS]* ]]; then
		shutdownApp $app_name;
	fi

    if [[ "$jitsimeet" == *[rR]* ]]; then
        dockerDownUp $app_name;
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
        echo "---- $menu_number. Downloading latest GitHub release"
        echo ""

		latest_tag=$(git ls-remote --refs --sort="version:refname" --tags $git_url | cut -d/ -f3- | tail -n1)
		echo "The latest tag is: $latest_tag"

		local result=$(mkdirFolders $containers_dir$app_name)
		checkSuccess "Creating $app_name container installation folder"
		local result=$(cd $containers_dir$app_name && sudo rm -rf $containers_dir$app_name/$latest_tag.zip)
		checkSuccess "Deleting zip file to prevent conflicts"
		local result=$(createTouch $latest_tag.txt && echo 'Installed "$latest_tag" on "$backupDate"!' > $latest_tag.txt)
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

        if [[ $compose_setup == "default" ]]; then
		    setupComposeFileNoApp $app_name;
        elif [[ $compose_setup == "app" ]]; then
            setupComposeFileApp $app_name;
        fi

		((menu_number++))
        echo ""
        echo "---- $menu_number. Updating file permissions before starting."
        echo ""

		fixPermissionsBeforeStart $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Setting up .env file for setup"
        echo ""

		setupEnvFile;

		# Updating custom .env values
		local result=$(sudo sed -i "s|CONFIG=~/.jitsi-meet-cfg|CONFIG=$containers_dir$app_name/.jitsi-meet-cfg|g" $containers_dir$app_name/.env)
		checkSuccess "Updating .env file with new install path"

		local result=$(sudo sed -i "s|#PUBLIC_URL=https://meet.example.com|PUBLIC_URL=https://$host_setup|g" $containers_dir$app_name/.env)
		checkSuccess "Updating .env file with Public URL to $host_setup"

		# Values are missing from the .env by default for some reason
		# https://github.com/jitsi/docker-jitsi-meet/commit/12051700562d9826f9e024ad649c4dd9b88f94de#diff-b335630551682c19a781afebcf4d07bf978fb1f8ac04c6bf87428ed5106870f5
		local result=$(echo "XMPP_DOMAIN=meet.jitsi" | sudo tee -a "$containers_dir$app_name/.env")
		checkSuccess "Updating .env file with missing option : XMPP_DOMAIN"

		local result=$(echo "XMPP_SERVER=xmpp.meet.jitsi" | sudo tee -a "$containers_dir$app_name/.env")
		checkSuccess "Updating .env file with missing option : XMPP_SERVER"

		local result=$(echo "JVB_PORT=10000" | sudo tee -a "$containers_dir$app_name/.env")
		checkSuccess "Updating .env file with missing option : JVB_PORT"

		local result=$(echo "JVB_TCP_MAPPED_PORT=4443" | sudo tee -a "$containers_dir$app_name/.env")
		checkSuccess "Updating .env file with missing option : JVB_TCP_MAPPED_PORT"

		local result=$(echo "JVB_TCP_PORT=4443" | sudo tee -a "$containers_dir$app_name/.env")
		checkSuccess "Updating .env file with missing option : JVB_TCP_PORT"

		local result=$(cd "$containers_dir$app_name" && sudo ./gen-passwords.sh)
		checkSuccess "Running Jitsi Meet gen-passwords.sh script"

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		whitelistAndStartApp $app_name install;

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
	jitsimeet=n
}