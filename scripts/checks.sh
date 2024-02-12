#!/bin/bash

checkRequirements()
{  
	echo ""
	echo "#####################################"
	echo "###      Checking Requirements    ###"
	echo "#####################################"
	echo ""
	isNotice "Requirements are about to be installed."
	isNotice "Edit the config_requirements if you want to disable anything before starting."
	echo ""

	if [[ $CFG_REQUIREMENT_ROOT == "true" ]]; then
		# Check if script is run as root
		if [[ $EUID -ne 0 ]]; then
			echo "This script must be run as root."
			exit 1
		else
			isSuccessful "Script ran under root user."
		fi
	fi

	if [[ $CFG_REQUIREMENT_COMMAND == "true" ]]; then
		# Custom command check
		if sudo grep -q "easydocker" ~/.bashrc; then
			isSuccessful "Custom command 'easydocker' installed."
		else
			checkSuccess "No custom command installed, did you run the init.sh first?"
			echo ""
			isNotice "Please run the following command:"
			isNotice "cd ~ && chmod 0755 init.sh && ./init.sh run && source ~/.bashrc && easydocker"
			echo ""
			isNotice "Exiting...."
			exit
		fi
	fi

	if [[ $CFG_REQUIREMENT_WIREGUARD == "true" ]]; then
		# Check if WireGuard is already installed and load params
		if [[ -e /etc/wireguard/params ]]; then
			isSuccessful "Wireguard is installed."
		else
			isNotice "Wireguard is not installed. Setup will start soon."
			((preinstallneeded++)) 
		fi
	fi
	
	if [[ "$OS" == [1234567] ]]; then
		ISCOMP=$( (docker-compose -v ) 2>&1 )
		ISUFW=$( (sudo ufw status ) 2>&1 )
		ISUFWD=$( (sudo ufw-docker) 2>&1 )
		ISCRON=$( (sudo -u $sudo_user_name crontab -l) 2>&1 )

		if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
			local ISUSER=$( (sudo id -u "$CFG_DOCKER_INSTALL_USER"))
			if [[ "$ISUSER" == *"no such user"* ]]; then
				ISACT=$(command -v docker &> /dev/null)
			fi
		elif [[ $CFG_DOCKER_INSTALL_TYPE == "root" ]]; then
			ISACT=$( (sudo systemctl is-active docker ) 2>&1 )
		fi
	fi

	if [[ $CFG_REQUIREMENT_CONFIG == "true" ]]; then
		checkConfigFilesEdited;
		checkConfigFilesMissingVariables;
	fi
	
	if [[ $CFG_REQUIREMENT_PASSWORDS == "true" ]]; then
		### Password randomizer
		pass_found=0
		files_with_password=()

		for config_file in "$configs_dir"/*; do
			if [ -f "$config_file" ] && grep -q "RANDOMIZEDPASSWORD" "$config_file"; then
				files_with_password+=("$(basename "$config_file")")  # Get only the filename
				pass_found=1
			fi
		done

		if [ "$pass_found" -eq 0 ]; then
			isSuccessful "No passwords found to change."
		else
			isSuccessful "Passwords found to change in the following files:"
			isNotice "${files_with_password[*]}"  # Join the array elements with spaces
			((preinstallneeded++))
		fi
	fi

	if [[ $CFG_REQUIREMENT_DATABASE == "true" ]]; then
		### Database file
		if [ -f "$docker_dir/$db_file" ] ; then
			isSuccessful "Installed Apps Database file found"
		else
			isNotice "Database file not found yet. Setup will start soon."
			((preinstallneeded++)) 
		fi
	fi

	# SSH Keys
	if [[ $CFG_REQUIREMENT_SSHKEY_ROOT == "true" ]]; then
		if checkSSHSetupKeyPair "root"; then
			isSuccessful "The SSH Key(s) for root appears to be setup."
		else
			isNotice "An SSH Key for root is not setup."
			SSHKEY_SETUP_NEEDED="true"
			((preinstallneeded++))
		fi
	fi
	if [[ $CFG_REQUIREMENT_SSHKEY_EASYDOCKER == "true" ]]; then
		if checkSSHSetupKeyPair "$sudo_user_name"; then
			isSuccessful "The SSH Key(s) for $sudo_user_name appears to be setup."
		else
			isNotice "An SSH Key for $sudo_user_name is not setup."
			SSHKEY_SETUP_NEEDED="true"
			((preinstallneeded++))
		fi
	fi
	if [[ $CFG_REQUIREMENT_SSHKEY_DOCKERINSTALL == "true" ]]; then
		if checkSSHSetupKeyPair "$CFG_DOCKER_INSTALL_USER"; then
			isSuccessful "The SSH Key(s) for $CFG_DOCKER_INSTALL_USER appears to be setup."
		else
			isNotice "An SSH Key for $CFG_DOCKER_INSTALL_USER is not setup."
			SSHKEY_SETUP_NEEDED="true"
			((preinstallneeded++))
		fi
	fi
	if [[ $CFG_REQUIREMENT_SSH_DISABLE_PASSWORDS == "true" ]]; then
		if grep -q "PasswordAuthentication no" $sshd_config; then
			isSuccessful "SSH Password appears to be disabled."
		else
			isNotice "Password Authentication has not been disabled."
			SSHKEY_SETUP_NEEDED="true"
			((preinstallneeded++))
		fi
	fi

	if [[ $CFG_REQUIREMENT_DOCKER_CE == "true" ]]; then
		### Docker CE
		if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
			if [[ "$ISACT" != "/usr/bin/docker" ]]; then
				isSuccessful "Docker appears to be installed and running."
			else
				isNotice "Docker does not appear to be installed. Setup will start soon."
				((preinstallneeded++)) 
			fi
		elif [[ $CFG_DOCKER_INSTALL_TYPE == "root" ]]; then
			if [[ "$ISACT" == "active" ]]; then
				isSuccessful "Docker appears to be installed and running."
			else
				isNotice "Docker does not appear to be installed. Setup will start soon."
				((preinstallneeded++)) 
			fi
		fi
	fi

	if [[ $CFG_REQUIREMENT_DOCKER_COMPOSE == "true" ]]; then
		### Docker Compose
		if [[ "$ISCOMP" != *"command not found"* ]]; then
			isSuccessful "Docker-compose appears to be installed."
		else
			isNotice "Docker-compose does not appear to be installed. Setup will start soon."
			((preinstallneeded++)) 
		fi
	fi
	
	if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
		### Docker Rootless
		if sudo grep -q "ROOTLESS" $sysctl; then
			isSuccessful "Docker Rootless appears to be installed."
		else
			isNotice "Docker Rootless does not appear to be installed. Setup will start soon."
			((preinstallneeded++)) 
		fi
	fi

	if [[ $CFG_REQUIREMENT_DOCKER_NETWORK == "true" ]]; then
		if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
			if runCommandForDocker "docker network ls | grep -q $CFG_NETWORK_NAME"; then
				isSuccessful "Docker Network $CFG_NETWORK_NAME appears to be installed."
			else
				isNotice "Docker Network $CFG_NETWORK_NAME not found. Setup will start soon."
				((preinstallneeded++)) 
			fi
		elif [[ $CFG_DOCKER_INSTALL_TYPE == "root" ]]; then
			if docker network ls | grep -q $CFG_NETWORK_NAME; then
				isSuccessful "Docker Network $CFG_NETWORK_NAME appears to be installed."
			else
				isNotice "Docker Network $CFG_NETWORK_NAME not found. Setup will start soon."
				((preinstallneeded++)) 
			fi
		fi
	fi
	
	if [[ $CFG_REQUIREMENT_UFW == "true" ]]; then
		### UFW Firewall
		if [[ "$ISUFW" != *"command not found"* ]]; then
			isSuccessful "UFW Firewall appears to be installed."
		else
			isNotice "UFW Firewall does not appear to be installed. Setup will start soon."
			((preinstallneeded++)) 
		fi
	fi

	if [[ $CFG_REQUIREMENT_UFWD == "true" ]]; then
		if [[ $CFG_DOCKER_INSTALL_TYPE == "root" ]]; then
			### UFW Docker
			if [[ "$ISUFWD" != *"command not found"* ]]; then
				isSuccessful "UFW-Docker Fix appears to be installed."
			else
				isNotice "UFW-Docker Fix does not appear to be installed. Setup will start soon."
				((preinstallneeded++)) 
			fi
		fi
	fi

	if [[ $CFG_REQUIREMENT_MANAGER == "true" ]]; then
		### Docker Manager User Creation
		if userExists "$CFG_DOCKER_MANAGER_USER"; then
			isSuccessful "The Docker Manager User appears to be setup."
		else
			isNotice "The Docker Manager User is not setup."
			((preinstallneeded++)) 
		fi
	fi

	if [[ $CFG_REQUIREMENT_SSLCERTS == "true" ]]; then
		### SSL Certificates
		domains=()
		for domain_num in {1..9}; do
			domain="CFG_DOMAIN_$domain_num"
			domain_value=$(sudo grep  "^$domain=" $configs_dir$config_file_general | cut -d '=' -f 2 | tr -d '[:space:]')
			if [ -n "$domain_value" ]; then
				domains+=("$domain_value")
			fi
		done

		missing_ssl=()
		for domain_value in "${domains[@]}"; do
			key_file="$ssl_dir/${domain_value}.key"
			crt_file="$ssl_dir/${domain_value}.crt"

			if [ -f "$key_file" ] || [ -f "$crt_file" ]; then
				isSuccessful "Certificate for domain $domain_value installed."
			else
				missing_ssl+=("$domain_value")
				isNotice "Certificate for domain $domain_value not found. Setup will start soon."
			fi
		done

		if [ ${#missing_ssl[@]} -eq 0 ]; then
			isSuccessful "SSL certificates are setup for all domains."
			SkipSSLInstall=true
		else
			isNotice "An SSL certificate is missing for the following domain: ${missing_ssl[*]}"
			((preinstallneeded++)) 
		fi
	fi


	if [[ $CFG_REQUIREMENT_SWAPFILE == "true" ]]; then
		### Swap file
		if [ -f "$swap_file" ]; then
			isSuccessful "Swapfile appears to be installed."
		else
			isNotice "Swapfile does not appears to be installed."
			((preinstallneeded++)) 
		fi
	fi

	if [[ $CFG_REQUIREMENT_CRONTAB == "true" ]]; then
		### Crontab
		if [[ "$ISCRON" != *"command not found"* ]] && sudo -u $sudo_user_name crontab -l 2>/dev/null | grep -q "cron is set up for $sudo_user_name"; then
			isSuccessful "Crontab is successfully set up."
		else
			isNotice "Crontab not installed. Setup will start soon."
			((preinstallneeded++))
		fi
	fi

	if [[ $CFG_REQUIREMENT_SSHREMOTE == "true" ]]; then
		### Custom SSH Remote Install
		# Check if the hosts line is empty or not found in the config file
		ssh_hosts_line=$(sudo grep  '^CFG_IPS_SSH_SETUP=' $configs_dir$config_file_general)
		if [ -n "$ssh_hosts_line" ]; then
			ssh_hosts=${ssh_hosts_line#*=}
			ip_found=0
			# Split the comma-separated IP addresses into an array
			IFS=',' read -ra ip_addresses <<< "$ssh_hosts"
			# Loop through the IP addresses
			for ip in "${ip_addresses[@]}"; do
				ip_found=1
			done

			if [ "$ip_found" -eq 0 ]; then
				isSuccessful "No for Remote SSH Install IP has been found to setup"
			else
				isSuccessful "Remote SSH Install IP(s) have been found to setup"
				setupSSHRemoteKeys=true
				((preinstallneeded++)) 
			fi
		else
			isSuccessful "No hosts found in the config file."
		fi
	fi

	if [[ $CFG_REQUIREMENT_SUGGEST_INSTALLS == "true" ]]; then
		local traefik_status=$(checkAppInstalled "traefik" "docker")
		local wireguard_status=$(checkAppInstalled "wireguard" "docker")
		if [[ "$traefik_status" == "installed" && "$wireguard_status" == "installed" ]]; then
			isSuccessful "All suggested applications are successfully set up."
		else
			isNotice "Traefik or Wireguard not installed. Setup will start soon."
			((preinstallneeded++))
		fi
	fi

	if [[ "$preinstallneeded" -ne 0 ]]; then
		startPreInstall;
	fi

	startScan;
	resetToMenu;
} 