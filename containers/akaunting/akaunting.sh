#!/bin/bash

# Category : user
# Description : Akaunting - Invoicing Solution *UNFINISHED* (c/u/s/r/i):

installAkaunting()
{
    local passedValue="$1"

    if [[ "$passedValue" == "install" ]]; then
        akaunting=i
    fi

    if [[ "$akaunting" == *[cCtTuUsSrRiI]* ]]; then
        setupConfigToContainer --silent akaunting;
		local app_name=$CFG_AKAUNTING_APP_NAME
		setupInstallVariables $app_name;
	fi
    
    if [[ "$akaunting" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

	if [[ "$akaunting" == *[uU]* ]]; then
		uninstallApp $app_name;
	fi

	if [[ "$akaunting" == *[sS]* ]]; then
		shutdownApp $app_name;
	fi

    if [[ "$akaunting" == *[rR]* ]]; then
        if [[ $compose_setup == "default" ]]; then
		    dockerDownUpDefault $app_name;
        elif [[ $compose_setup == "app" ]]; then
            dockerDownUpAdditionalYML $app_name;
        fi
    fi

    if [[ "$akaunting" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###          Install $app_name"
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
		checkAllowOrDenyPorts;
        
		((menu_number++))
        echo ""
        echo "---- $menu_number. Pulling a default Akaunting docker-compose.yml file and making edits."
        echo ""

		local result=$(runCommandForDockerInstallUser "cd $containers_dir && git clone https://github.com/akaunting/docker $containers_dir$app_name")
		checkSuccess "Cloning the Akaunting GitHub repo"

        if [[ $compose_setup == "default" ]]; then
		    setupComposeFileNoApp $app_name;
        elif [[ $compose_setup == "app" ]]; then
            setupComposeFileApp $app_name;
        fi

		local result=$(sudo sed -i 's|- akaunting-data:/var/www/html|- ./akaunting-data/:/var/www/html|g' $containers_dir$app_name/docker-compose.yml)
		checkSuccess "Updating akaunting-data to persistant storage"

		local result=$(sudo sed -i 's|- akaunting-db:/var/lib/mysql|- ./akaunting-db/:/var/lib/mysql|g' $containers_dir$app_name/docker-compose.yml)
		checkSuccess "Updating akaunting-db to persistant storage"

		local result=$(sudo sed -i "s|8080|$port|g" $containers_dir$app_name/docker-compose.yml)
		checkSuccess "Updating port 8080 to $port in docker-compose.yml"
		
		# Find the last instance of "networks:" in the file and get its line number
		last_network=$(sudo grep  -n 'networks:' "$containers_dir$app_name/docker-compose.yml" | cut -d: -f1 | tail -n 1)
		if [ -n "$last_network" ]; then
			local result=$(sudo sed -i "${last_network},${last_network}+2s/^/# /" "$containers_dir$app_name/docker-compose.yml")
			checkSuccess "Comment out the last 'networks:' and the 2 lines below it."
		fi


		((menu_number++))
        echo ""
        echo "---- $menu_number. Updating file permissions before starting."
        echo ""

		fixPermissionsBeforeStart $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Setting up .env files."
        echo ""

		local result=$(copyFile $containers_dir$app_name/env/db.env.example $containers_dir$app_name/env/db.env)
		checkSuccess "Copying example db.env for setup"

		local result=$(copyFile $containers_dir$app_name/env/run.env.example $containers_dir$app_name/env/run.env)
		checkSuccess "Copying example run.env for setup"
	
		local result=$(sudo sed -i "s/akaunting.example.com/$host_setup/g" $containers_dir$app_name/env/run.env)
		checkSuccess "Updating Domain in run.env to $host_setup"
		
		local result=$(sudo sed -i "s/en-US/$CFG_AKAUNTING_LANGUAGE/g" $containers_dir$app_name/env/run.env)
		checkSuccess "Updating language in run.env to $CFG_AKAUNTING_LANGUAGE"	

		local result=$(sudo sed -i "s/akaunting_password/$CFG_AKAUNTING_PASSWORD/g" $containers_dir$app_name/env/db.env)
		checkSuccess "Setting Akaunting Password to generated password in config file"

        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start Akaunting"
        echo ""

		whitelistAndStartApp $app_name install;

		# Check if this is a first time setup
		if [ -f "$containers_dir$app_name/SETUPINITIALIZED" ]; then
			isNotice "Running setup as initial setup file not found."

			local result=$(createTouch $containers_dir$app_name/SETUPINITIALIZED)
			checkSuccess "Creating initizilation file"

			if [[ "$OS" == [1234567] ]]; then
				if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
					local result=$(runCommandForDockerInstallUser "cd $containers_dir$app_name && AKAUNTING_SETUP=true docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml up -d)")
					isSuccessful "Starting $app_name up with initial setup flag"
				elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
					local result=$(cd $containers_dir$app_name && AKAUNTING_SETUP=true sudo -u $easydockeruser docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml up -d)
					isSuccessful "Starting $app_name up with initial setup flag"
				fi
			fi
		else
			isNotice "It seems $app_name is already setup, using the normal up command"
			dockerDownUpAdditionalYML $app_name;
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
        echo "    External : http://$public_ip:$port/"
        echo "    Local : http://$ip_setup:$port/"
        echo ""

		menu_number=0
        sleep 3s
        cd
	fi
	akaunting=n
}