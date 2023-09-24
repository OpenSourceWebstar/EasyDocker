#!/bin/bash

# Description : Mailcow - Mail Server *UNFINISHED* (c/u/s/r/i):

installMailcow()
{
    app_name=$CFG_MAILCOW_APP_NAME
    setupInstallVariables $app_name;
	easy_setup=$CFG_MAILCOW_EASY_SETUP
	using_caddy=$CFG_MAILCOW_USING_CADDY

    if [[ "$mailcow" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

	if [[ "$mailcow" == *[uU]* ]]; then
		uninstallApp $app_name;
	fi

	if [[ "$mailcow" == *[sS]* ]]; then
		shutdownApp;
	fi

	if [[ "$mailcow" == *[rR]* ]]; then
		dockerDownUpAdditionalYML $app_name;
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

		setupIPsAndHostnames $app_name;

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

			scan_result=$(sudo -u $easydockeruser ss -tlpn | sudo grep  -E -w "$ports_to_scan")

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
        echo "---- $menu_number. Pulling Mailcow GitHub repo into the $install_dir$app_name folder"
        echo ""

		result=$(sudo -u $easydockeruser git clone https://github.com/mailcow/mailcow-dockerized $install_dir/mailcow)
		checkSuccess "Cloning Mailcow Dockerized GitHub repo"

		result=$(copyFile $script_dir/containers/docker-compose.$app_name.yml $install_dir$app_name/docker-compose.$app_name.yml | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" 2>&1)
		checkSuccess "Copying docker-compose.$app_name.yml to the $app_name folder"

		((menu_number++))
	    echo ""
        echo "---- $menu_number. Pulling Mailcow GitHub repo into the /docker/ folder"
        echo ""

		# Custom values from files
		result=$(sudo sed -i "s/DOMAINNAMEHERE/$domain_full/g" $install_dir$app_name/docker-compose.$app_name.yml)
		checkSuccess "Updating Domain Name in the docker-compose.$app_name.yml file"

		result=$(sudo sed -i "s/IPADDRESSHERE/$ip_setup/g" $install_dir$app_name/docker-compose.$app_name.yml)
		checkSuccess "Updating IP Address in the docker-compose.$app_name.yml file"

		result=$(sudo sed -i "s/PORTHERE/$COWP80C/g" $install_dir$app_name/docker-compose.$app_name.yml)
		checkSuccess "Updating Port to $$COWP80C in the docker-compose.$app_name.yml file"
		
		if [[ "$using_caddy" == "false" ]]; then
			# Setup SSL Transfer scripts
			result=$(copyFile $script_dir/resources/caddy/caddy-to-mailcow-ssl.sh $install_dir$app_name/caddy-to-mailcow-ssl.sh | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" 2>&1)
			checkSuccess "Copying SSL caddy-to-mailcow-ssl.sh script to docker folder."
			
			result=$(sudo sed -i "s/DOMAINNAMEHERE/mail.$domain_full/g" $install_dir$app_name/caddy-to-mailcow-ssl.sh)
			checkSuccess "Setting Domain Name in caddy-to-mailcow-ssl.sh"
			
			result=$(sudo chmod 0755 /docker/mailcow/caddy-to-mailcow-ssl.sh)
			checkSuccess "Updating permissions for caddy-to-mailcow-ssl.sh"
			
			# Setup crontab
			job="0 * * * * /bin/bash $install_dir$app_name/caddy-to-mailcow-ssl.sh"
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
        	result=$(sudo sed -i 's/HTTP_PORT=80/HTTP_PORT='$COWP80C'/' $install_dir/mailcow/mailcow.conf)
        	checkSuccess "Updating the mailserver.conf to custom http port"
		fi
		if [[ "$COWP443_PROMPT" == [yY] ]]; then
        	result=$(sudo sed -i 's/HTTPS_PORT=443/HTTPS_PORT='$COWP443C'/' $install_dir/mailcow/mailcow.conf)
        	checkSuccess "Updating the mailserver.conf to custom https port"
		fi
		if [[ "$COWLE" == [yY] ]]; then
        	result=$(sudo sed -i 's/SKIP_LETS_ENCRYPT=n/SKIP_LETS_ENCRYPT=y/' $install_dir/mailcow/mailcow.conf)
        	checkSuccess "Updating the mailserver.conf to disable SSL install"
		fi
		if [[ "$COWCD" == [nN] ]]; then
        	result=$(sudo sed -i 's/SKIP_CLAMD=n/SKIP_CLAMD=y/' $install_dir/mailcow/mailcow.conf)
        	checkSuccess "Updating the mailserver.conf to disable ClamD Antivirus"
		fi

		((menu_number++))
        echo ""
        echo "---- $menu_number. Updating file permissions before starting."
        echo ""

		fixPermissionsBeforeStart;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		dockerDownUpAdditionalYML $app_name;

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