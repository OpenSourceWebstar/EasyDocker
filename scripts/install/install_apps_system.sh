#!/bin/bash

app_name="$1"

installFail2Ban()
{
	app_name=fail2ban

    if [[ "$fail2ban" == *[uU]* ]]; then
        uninstallApp;
    fi

    if [[ "$fail2ban" == *[sS]* ]]; then
        shutdownApp;
    fi

    if [[ "$fail2ban" == *[rR]* ]]; then
        dockerDownUpDefault;
    fi

    if [[ "$fail2ban" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###     Install $app_name"
        echo "##########################################"
        echo ""

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
        echo "---- $menu_number. Setting up AbuseIPDB for fail2ban if api key is provided"
        echo ""

        if [ -n "$CFG_ABUSEIPDB_APIKEY" ]; then
            checkSuccess "API key found, setting up the config file."

            result=$(cd $install_path$app_name && touch $install_path$app_name/logs/auth.log)
            checkSuccess "Creating Auth.log file"

            result=$(mkdir -p $install_path$app_name/config/$app_name $install_path$app_name/config/$app_name/action.d)
            checkSuccess "Creating config and action.d folders"

            # AbuseIPDB
            result=$(cd $install_path$app_name/config/$app_name/action.d/ && curl -o abuseipdb.conf https://raw.githubusercontent.com/fail2ban/fail2ban/0.11/config/action.d/abuseipdb.conf)
            checkSuccess "Downloading abuseipdb.conf from GitHub"
            
            result=$(sed -i "s/abuseipdb_apikey =/abuseipdb_apikey =$CFG_ABUSEIPDB_APIKEY/g" $install_path$app_name/config/$app_name/action.d/abuseipdb.conf)
            checkSuccess "Setting up abuseipdb_apikey"

            result=$(docker cp $install_path$app_name/config/$app_name/action.d/abuseipdb.conf $app_name:/etc/$app_name/action.d/abuseipdb.conf)
            checkSuccess "Copying abuseipdb.conf file"

            # Jail.local
		    result=$(sudo cp $resources_dir/$app_name/jail.local $install_path$app_name/config/$app_name/jail.local >> $script_dir/docker-script-install.log 2>&1)
            checkSuccess "Coping over jail.local from Resources folder"

            result=$(sed -i "s/my-api-key/$CFG_ABUSEIPDB_APIKEY/g" $install_path$app_name/config/$app_name/jail.local)
            checkSuccess "Setting up AbuseIPDB API Key in jail.local file"

            result=$(sed -i "s/ips_whitelist/$CFG_IPS_WHITELIST/g" $install_path$app_name/config/$app_name/jail.local)
            checkSuccess "Setting up IP Whitelist in jail.local file"

		    dockerDownUpDefault;
        else
            isNotice "No API key found, please provide one if you want to use AbuseIPDB"
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
        echo "    Your $app_name service is now online!"
        echo ""

		menu_number=0
        sleep 3s
        cd
    fi
    fail2ban=n
}

installTraefik()
{
    app_name=traefik
    host_name=proxy
	domain_number=1
    public=true
    port=8080

    if [[ "$traefik" == *[uU]* ]]; then
        uninstallApp;
    fi

    if [[ "$traefik" == *[sS]* ]]; then
        shutdownApp;
    fi

    if [[ "$traefik" == *[rR]* ]]; then
        # Fix permissions if files have been changed to avoid non loading
        result=$(chmod 600 "$install_path$app_name/etc/certs/acme.json")
        checkSuccess "Set permissions to acme.json file for $app_name"
        
        dockerDownUpDefault;
    fi

    if [[ "$traefik" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###         Install $app_name"
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
		
        # Create necessary directories and set permissions
        result=$(mkdir -p "$install_path$app_name/etc" "$install_path$app_name/etc/certs")
        checkSuccess "Create /etc/ and /etc/certs Directories"

        result=$(sudo chown 1000 "$install_path$app_name/etc" "$install_path$app_name/etc/certs")
        checkSuccess "Set permissions for /etc/ and /etc/certs/ Directories"

        # Create and secure the acme.json file
        result=$(touch "$install_path$app_name/etc/certs/acme.json")
        checkSuccess "Created acme.json file for $app_name"

        result=$(chmod 600 "$install_path$app_name/etc/certs/acme.json")
        checkSuccess "Set permissions to acme.json file for $app_name"

        # Copy the Traefik configuration file and customize it
        result=$(sudo cp "$resources_dir/$app_name/traefik.yml" "$install_path$app_name/etc/traefik.yml")
        checkSuccess "Copy Traefik configuration file for $app_name"

        # Replace the placeholder email with the actual email for Let's Encrypt SSL certificates
        result=$(sed -i "s/your-email@example.com/$CFG_EMAIL/g" "$install_path$app_name/etc/traefik.yml")
        checkSuccess "Configured Traefik with email: $CFG_EMAIL for $app_name"

		editComposeFileDefault;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		dockerDownUpDefault;

		((menu_number++))
		echo ""
        echo "---- $menu_number. Allowing $app_name through the UFW Firewall"
		echo ""

        result=$(sudo ufw-docker allow $app_name 80/tcp)
		checkSuccess "Opening port 80 (HTTP) for $app_name with ufw-docker"

        result=$(sudo ufw-docker allow $app_name 443/tcp)
		checkSuccess "Opening port 443 (HTTPS) for $app_name with ufw-docker"

		((menu_number++))
		echo ""
        echo "---- $menu_number. Restarting $app_name after firewall changes"
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
    traefik=n
}

installCaddy()
{
    app_name=caddy
    host_name=proxy
	domain_number=1
    public=false

    if [[ "$caddy" == *[uU]* ]]; then
        uninstallApp;
    fi

    if [[ "$caddy" == *[sS]* ]]; then
        shutdownApp;
    fi

    if [[ "$caddy" == *[rR]* ]]; then
        dockerDownUpDefault;
    fi

    if [[ "$caddy" == *[iI]* ]]; then
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
		
		touch $install_path$app_name/Caddyfile
		
		editComposeFileDefault;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		dockerDownUpDefault;

		((menu_number++))
		echo ""
        echo "---- $menu_number. Allowing $app_name through the UFW Firewall"
		echo ""

        result=$(sudo ufw-docker allow $app_name 80/tcp)
		checkSuccess "Opening port 80 (HTTP) for $$app_name with ufw-docker"

        result=$(sudo ufw-docker allow $app_name 443/tcp)
		checkSuccess "Opening port 443 (HTTPS) for $$app_name with ufw-docker"

		((menu_number++))
		echo ""
        echo "---- $menu_number. Restarting $app_name after firewall changes"
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
    caddy=n
}

installWireguard()
{
    app_name=wireguard
    host_name=wireguard
	domain_number=1
    public=false
    port=51821
    
    if [[ "$wireguard" == *[uU]* ]]; then
        uninstallApp;
    fi

    if [[ "$wireguard" == *[sS]* ]]; then
        shutdownApp;
    fi

    if [[ "$wireguard" == *[rR]* ]]; then
        dockerDownUpDefault;
    fi

    if [[ "$wireguard" == *[iI]* ]]; then
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
        echo "---- $menu_number. Enabling IP forwarding"
		echo ""

        result=$(sudo sed -i "s/#net.ipv4.ip_forward/net.ipv4.ip_forward/g" /etc/sysctl.d/99-sysctl.conf)
		checkSuccess "Enabling IPv4 IP Forwarding in the 99-sysctl.conf file (Kernel)"

        result=$(sudo sysctl -p)
		checkSuccess "Apply changes made to the System's Kernel "
		

		((menu_number++))
		echo ""
        echo "---- $menu_number. Running the docker-compose.yml to Install $app_name"
        echo ""

		dockerDownUpDefault;

		((menu_number++))
		echo ""
        echo "---- $menu_number. Allowing $app_name through the UFW Firewall"
		echo ""

		sudo ufw-docker allow wg-easy 51820/udp

		((menu_number++))
		echo ""
        echo "---- $menu_number. Restarting $app_name after firewall changes"
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
    wireguard=n
}

installPihole()
{
    app_name=pihole
    host_name=pihole
	domain_number=1
    public=false
    port=3232

    if [[ "$pihole" == *[uU]* ]]; then
        uninstallApp;
    fi

    if [[ "$pihole" == *[sS]* ]]; then
        shutdownApp;
    fi

    if [[ "$pihole" == *[rR]* ]]; then
        dockerDownUpDefault;
    fi

    if [[ "$pihole" == *[iI]* ]]; then
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
        echo "---- $menu_number. Editing local variables for DNS server to $app_name"
        echo ""

        if grep -q "$ip_setup" /etc/resolv.conf; then
            checkSuccess "IP Already setup, no need to make changes"
        else
            isQuestion "Do you want to change the default DNS server on the host to use Pi-Hole? (y/n): "
            read -rp "" PHDNS

            if [[ "$PHDNS" =~ ^[yY]$ ]]; then
                # Updating nameserver address in /etc/resolv.conf
                result=$(sudo sed -i "/nameserver/c\#nameserver\nnameserver $ip_setup" /etc/resolv.conf)
                checkSuccess "Updating nameserver in resolv.conf"

                # Updating DNS address in /etc/systemd/resolved.conf
                result=$(sudo sed -i "/DNS=/c\#DNS=\nDNS=$ip_setup" /etc/systemd/resolved.conf)
                checkSuccess "Updating DNS in resolved.conf"

                # Restarting systemd-resolved to apply changes
                result=$(sudo systemctl restart systemd-resolved)
                checkSuccess "Restarting systemd-resolved"
            fi
        fi

		((menu_number++))
        echo ""
        echo "---- $menu_number. Setting up database records"
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
        echo "    NOTE - The password to login in defined in the yml install file that was installed"
        echo ""
        
		menu_number=0
        sleep 3s
        cd
    fi
    pihole=n
}

installPortainer()
{
    app_name=portainer
    host_name=portainer
	domain_number=1
    public=false
    port=9000

    if [[ "$portainer" == *[uU]* ]]; then
        uninstallApp;
    fi

    if [[ "$portainer" == *[sS]* ]]; then
        shutdownApp;
    fi

    if [[ "$portainer" == *[rR]* ]]; then
        dockerDownUpDefault;
    fi

    if [[ "$portainer" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###      Installing $app_name"
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
		dockerDownUpDefault

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
    portainer=n
}

installWatchtower()
{
	app_name=watchtower

    if [[ "$watchtower" == *[uU]* ]]; then
        uninstallApp;
    fi

    if [[ "$watchtower" == *[sS]* ]]; then
        shutdownApp;
    fi

    if [[ "$watchtower" == *[rR]* ]]; then
        dockerDownUpDefault;
    fi

    if [[ "$watchtower" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###           Install $app_name"
        echo "##########################################"
        echo ""

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
    
		menu_number=0
        sleep 3s
        cd
    fi
    watchtower=n
}

installDuplicati()
{
    app_name=duplicati
    host_name=backup
	domain_number=1
    public=false
    port=8200

    if [[ "$duplicati" == *[uU]* ]]; then
        uninstallApp;
    fi

    if [[ "$duplicati" == *[sS]* ]]; then
        shutdownApp;
    fi

    if [[ "$duplicati" == *[rR]* ]]; then
        dockerDownUpDefault;
    fi

    if [[ "$duplicati" == *[iI]* ]]; then
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
        echo "---- $menu_number. Running the docker-compose.yml to install and start $$app_name"
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
    duplicati=n
}

installDashy()
{
    app_name=dashy
    host_name=dashy
	domain_number=1
    public=false
    port=4000
    
    if [[ "$dashy" == *[uU]* ]]; then
        uninstallApp;
    fi

    if [[ "$dashy" == *[sS]* ]]; then
        shutdownApp;
    fi

    if [[ "$dashy" == *[rR]* ]]; then
        dockerDownUpDefault;
    fi

    if [[ "$dashy" == *[iI]* ]]; then
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
        echo "---- $menu_number. Setting up conf.yml file."
        echo ""

        result=$(sudo touch "$install_path$app_name/conf.yml")
        checkSuccess "Creating base conf.yml file"
        result=$(sudo cat "$resources_dir/$app_name/conf.yml" > "$install_path$app_name/conf.yml")
        checkSuccess "Copy contents of conf.yml configuration file"

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
    dashy=n
}