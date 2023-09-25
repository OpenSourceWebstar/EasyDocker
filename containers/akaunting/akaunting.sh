#!/bin/bash

# Category : user
# Description : Akaunting - Invoicing Solution *UNFINISHED* (c/u/s/r/i):

installAkaunting()
{
    passedValue="$1"

    if [[ "$passedValue" == "install" ]]; then
        akaunting=i
    fi

    if [[ -n  "$akaunting" || "$akaunting" != "n" ]]; then
        setupConfigToContainer akaunting;
		app_name=$CFG_AKAUNTING_APP_NAME
	fi
    
    if [[ "$akaunting" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

	if [[ "$akaunting" == *[uU]* ]]; then
		uninstallApp $app_name;
	fi

	if [[ "$akaunting" == *[sS]* ]]; then
		shutdownApp;
	fi

    if [[ "$akaunting" == *[rR]* ]]; then
		setupInstallVariables $app_name;
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
        echo "---- $menu_number. Checking custom DNS entry and IP for setup"
        echo ""

		setupInstallVariables $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Pulling a default Akaunting docker-compose.yml file and making edits."
        echo ""
		
		result=$(runCommandForDockerInstallUser "cd $install_dir && git clone https://github.com/akaunting/docker $install_dir$app_name")
		checkSuccess "Cloning the Akaunting GitHub repo"

        if [[ $compose_setup == "default" ]]; then
		    setupComposeFileNoApp $app_name;
        elif [[ $compose_setup == "app" ]]; then
            setupComposeFileApp $app_name;
        fi

		result=$(sudo sed -i 's|- akaunting-data:/var/www/html|- ./akaunting-data/:/var/www/html|g' $install_dir$app_name/docker-compose.yml)
		checkSuccess "Updating akaunting-data to persistant storage"

		result=$(sudo sed -i 's|- akaunting-db:/var/lib/mysql|- ./akaunting-db/:/var/lib/mysql|g' $install_dir$app_name/docker-compose.yml)
		checkSuccess "Updating akaunting-db to persistant storage"

		result=$(sudo sed -i "s|8080|$port|g" $install_dir$app_name/docker-compose.yml)
		checkSuccess "Updating port 8080 to $port in docker-compose.yml"
		
		# Find the last instance of "networks:" in the file and get its line number
		last_network=$(sudo grep  -n 'networks:' "$install_dir$app_name/docker-compose.yml" | cut -d: -f1 | tail -n 1)
		if [ -n "$last_network" ]; then
			result=$(sudo sed -i "${last_network},${last_network}+2s/^/# /" "$install_dir$app_name/docker-compose.yml")
			checkSuccess "Comment out the last 'networks:' and the 2 lines below it."
		fi


		((menu_number++))
        echo ""
        echo "---- $menu_number. Updating file permissions before starting."
        echo ""

		fixPermissionsBeforeStart;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Setting up .env files."
        echo ""

		result=$(copyFile $install_dir$app_name/env/db.env.example $install_dir$app_name/env/db.env)
		checkSuccess "Copying example db.env for setup"

		result=$(copyFile $install_dir$app_name/env/run.env.example $install_dir$app_name/env/run.env)
		checkSuccess "Copying example run.env for setup"
	
		result=$(sudo sed -i "s/akaunting.example.com/$host_setup/g" $install_dir$app_name/env/run.env)
		checkSuccess "Updating Domain in run.env to $host_setup"
		
		result=$(sudo sed -i "s/en-US/$CFG_AKAUNTING_LANGUAGE/g" $install_dir$app_name/env/run.env)
		checkSuccess "Updating language in run.env to $CFG_AKAUNTING_LANGUAGE"	

		result=$(sudo sed -i "s/akaunting_password/$CFG_AKAUNTING_PASSWORD/g" $install_dir$app_name/env/db.env)
		checkSuccess "Setting Akaunting Password to generated password in config file"

        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start Akaunting"
        echo ""

		whitelistAndStartApp $app_name;

		# Check if this is a first time setup
		if [ -f "$install_dir$app_name/SETUPINITIALIZED" ]; then
			isNotice "Running setup as initial setup file not found."

			result=$(createTouch $install_dir$app_name/SETUPINITIALIZED)
			checkSuccess "Creating initizilation file"

			if [[ "$OS" == [123] ]]; then
				if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
					result=$(runCommandForDockerInstallUser "cd $install_dir$app_name && AKAUNTING_SETUP=true docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml up -d)")
					isSuccessful "Starting $app_name up with initial setup flag"
				elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
					result=$(cd $install_dir$app_name && AKAUNTING_SETUP=true sudo -u $easydockeruser docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml up -d)
					isSuccessful "Starting $app_name up with initial setup flag"
				fi
			fi
		else
			isNotice "It seems $app_name is already setup, using the normal up command"
			dockerDownUpAdditionalYML $app_name;
		fi

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Opening ports if required"
        echo ""

        openAppPorts $app_name;

		((menu_number++))
		echo ""
        echo "---- $menu_number. Adding $app_name to the Apps Database table."
        echo ""

		databaseInstallApp;

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
	akaunting=n
}