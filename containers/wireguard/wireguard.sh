#!/bin/bash

# Category : system
# Description : Wireguard Easy - VPN Server (c/u/s/r/i):

installWireguard()
{
    if [[ "$wireguard" == *[cCtTuUsSrRiI]* ]]; then
        dockerConfigSetupToContainer silent wireguard;
        local app_name=$CFG_WIREGUARD_APP_NAME
		setupInstallVariables $app_name;
    fi
    
    if [[ "$wireguard" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

    if [[ "$wireguard" == *[uU]* ]]; then
        dockerUninstallApp $app_name;
    fi

    if [[ "$wireguard" == *[sS]* ]]; then
        dockerComposeDown $app_name;
    fi

    if [[ "$wireguard" == *[rR]* ]]; then
        dockerComposeRestart $app_name;
    fi

    if [[ "$wireguard" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###          Install $app_name"
        echo "##########################################"
        echo ""

		((menu_number++))
        echo ""
        echo "---- $menu_number. Checking if $app_name can be installed."
        echo ""

        dockerCheckAllowedInstall "$app_name" || return 1

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
        echo "---- $menu_number. Setting up the $app_name docker-compose.yml file."
		echo ""

        dockerComposeSetupFile $app_name;

		((menu_number++))
		echo ""
        echo "---- $menu_number. Enabling IP forwarding"
		echo ""

        if [ -f "/etc/sysctl.d/99-sysctl.conf" ]; then
            local result=$(sudo sed -i "s/#net.ipv4.ip_forward/net.ipv4.ip_forward/g" /etc/sysctl.d/99-sysctl.conf)
            checkSuccess "Enabling IPv4 IP Forwarding in the 99-sysctl.conf file (Kernel)"
            #local result=$(sudo sed -i "s/#net.ipv6.conf.all.forwarding/net.ipv6.conf.all.forwarding/g" /etc/sysctl.d/99-sysctl.conf)
            #checkSuccess "Enabling IPv6 IP Forwarding in the 99-sysctl.conf file (Kernel)"
        fi
        if [ -f "/etc/sysctl.conf" ]; then
            local result=$(sudo sed -i "s/#net.ipv4.ip_forward/net.ipv4.ip_forward/g" /etc/sysctl.conf)
            checkSuccess "Enabling IPv4 IP Forwarding in the sysctl.conf file (Kernel)"
            #local result=$(sudo sed -i "s/#net.ipv6.conf.all.forwarding/net.ipv6.conf.all.forwarding/g" /etc/sysctl.conf)
            #checkSuccess "Enabling IPv6 IP Forwarding in the sysctl.conf file (Kernel)"
        fi
        
        if [ -f "/etc/ufw/sysctl.conf" ]; then
            local result=$(sudo sed -i "s|#net/ipv4/ip_forward|net/ipv4/ip_forward|g" /etc/ufw/sysctl.conf)
            checkSuccess "Enabling IPv4 IP Forwarding in the ufw sysctl.conf file"
            #local result=$(sudo sed -i "s|#net/ipv6/conf/default/forwarding|net/ipv6/conf/default/forwarding|g" /etc/ufw/sysctl.conf)
            #checkSuccess "Enabling IPv6 IP Forwarding default in the ufw sysctl.conf file"
            #local result=$(sudo sed -i "s|#net/ipv6/conf/all/forwarding|net/ipv6/conf/all/forwarding|g" /etc/ufw/sysctl.conf)
            #checkSuccess "Enabling IPv6 IP Forwarding all in the ufw sysctl.conf file"
        fi

        local result=$(sudo sysctl -p)
		checkSuccess "Apply changes made to the System's Kernel "

		((menu_number++))
        echo ""
        echo "---- $menu_number. Updating file permissions before starting."
        echo ""

		fixPermissionsBeforeStart $app_name;

		((menu_number++))
		echo ""
        echo "---- $menu_number. Running the docker-compose.yml to Install $app_name"
        echo ""

		dockerComposeUpdateAndStartApp $app_name install;

		((menu_number++))
		echo ""
        echo "---- $menu_number. Restarting $app_name after firewall changes"
        echo ""

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
        echo "---- $menu_number. Opening port $usedport2 to the public for setup reasons."
        echo ""

		portOpen $app_name $usedport2/tcp install;

		((menu_number++))
        if [[ $compose_setup == "default" ]]; then
            local compose_file="docker-compose.yml"
        elif [[ $compose_setup == "app" ]]; then
            local compose_file="docker-compose.$app_name.yml"
        fi

        echo ""
        echo "    A WireGuard user must now be created to allow access into the system"
        echo "    Port $usedport2 has been opened publically to allow you to create a user : "
        echo "    The URL below is only valid for this part of the setup"
        echo ""
        echo "    Please create a WireGuard account and save it to access the system after setup"
        echo "    It may take 10+ seconds to load the panel, please be patient"
        echo ""
        echo "    URL : http://$public_ip_v4:$usedport2/"
        echo "    PASS : $password"
        echo ""

        while true; do
            echo ""
            isNotice "Setup is now available, please follow the instructions above."
            echo ""
            isQuestion "Have you followed the instructions above? (y/n): "
            read -p "" wireguard_instructions
            if [[ "$wireguard_instructions" == 'y' || "$wireguard_instructions" == 'Y' ]]; then
                break
            else
                isNotice "Please confirm the setup or provide a valid input."
            fi
        done

		((menu_number++))
		echo ""
        echo "---- $menu_number. Closing port $usedport2 to the public as initial setup completed."
        echo ""

		portClose $app_name $usedport2/tcp install;

		((menu_number++))
        echo ""
        echo "---- $menu_number. You can find $app_name files at $containers_dir$app_name"
        echo ""
        echo "    You can now navigate to your $app_name service using any of the options below : "
        echo ""

        menuShowFinalMessages $app_name;
        
		menu_number=0
        sleep 3s
        cd
    fi
    wireguard=n
}
