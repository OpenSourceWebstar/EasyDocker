#!/bin/bash

# Category : old
# Description : Virtualmin Webhost Proxy - *Requires Virtualmin* (c/u/s/r/i):

installVirtualminwebhost()
{
    if [[ "$virtualminwebhost" == *[cCtTuUsSrRiI]* ]]; then
        setupConfigToContainer silent virtualminwebhost;
        local app_name=$CFG_VIRTUALMINWEBHOST_APP_NAME
        setupInstallVariables $app_name;
    fi
    
    if [[ "$virtualminwebhost" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

    if [[ "$virtualminwebhost" == *[uU]* ]]; then
        uninstallApp $app_name;
    fi

    if [[ "$virtualminwebhost" == *[sS]* ]]; then
        shutdownApp $app_name;
    fi

    if [[ "$virtualminwebhost" == *[rR]* ]]; then
        dockerDownUp $app_name;
    fi
    
    if [[ "$virtualminwebhost" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###          Install $app_name"
        echo "##########################################"
        echo ""

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Checking if $app_name can be installed."
        echo ""

        checkAllowedInstall "$app_name" || return 1

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Setting up install folder and config file for $app_name."
        echo ""

        setupConfigToContainer "loud" "$app_name" "install";
        isSuccessful "Install folders and Config files have been setup for $app_name."

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Checking & Opening ports if required"
        echo ""

        # Port List
        #Service 	dhcpv6-client (546) 	UDP
        #Service 	dns (53) 	TCP/UDP
        #Service 	dns-over-tls (853) 	TCP
        #Service 	ftp (21) 	TCP
        #Service 	http (80) 	TCP
        #Service 	https (443) 	TCP
        #Service 	imap (143) 	TCP
        #Service 	imaps (993) 	TCP
        #Service 	mdns (5353) 	UDP
        #Service 	pop3 (110) 	TCP
        #Service 	pop3s (995) 	TCP
        #Service 	smtp (25) 	TCP
        #Service 	smtp-submission (587) 	TCP
        #Service 	smtps (465) 	TCP
        #Service 	ssh (22) 	TCP
        #Port 	20 	TCP
        #Port 	2222 	TCP
        #Port 	10000-10100 	TCP
        #Port 	20000 	TCP
        #Port 	49152-65535 	TCP

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
        echo "---- $menu_number. Setting up the $app_name docker-compose.yml file."
        echo ""

        setupComposeFile $app_name;

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Making edits to the Virtualminwebhost system files."
        echo ""
        
        local miniserv_conf="/etc/webmin/miniserv.conf"
        local config_conf="/etc/webmin/config"

        if [[ -f "$miniserv_conf" ]]; then
            sudo sed -i '/redirect_host=/d' "$miniserv_conf"
            sudo sed -i '/redirect_port=/d' "$miniserv_conf"
            echo "redirect_host=$host_setup" | sudo tee -a "$miniserv_conf" > /dev/null 2>&1
            echo "redirect_port=$usedport1" | sudo tee -a "$miniserv_conf" > /dev/null 2>&1
        else
            isError "Unable to find miniserv.conf, cancelling install..."
        fi

        if [[ -f "$config_conf" ]]; then
            sudo sed -i '/referers=/d' "$config_conf"
            echo "referers=$host_setup" | sudo tee -a "$config_conf" > /dev/null 2>&1
        else
            isError "Unable to find config, cancelling install..."
        fi

        while true; do
            echo ""
            isQuestion "Would you like to change the Virtualminwebhost root password? (y/n): "
            read -p "" virtualminwebhost_pass_choice
            if [[ -n "$virtualminwebhost_pass_choice" ]]; then
                break
            fi
            isNotice "Please provide a valid input."
        done
        if [[ "$virtualminwebhost_pass_choice" == [yY] ]]; then
            while true; do
                isQuestion "Enter the new password for the 'root' Webmin user: "
                read -s -p "" webmin_password
                if [ -n "$webmin_password" ] && [ ${#webmin_password} -ge 8 ]; then
                    resut=$(sudo /usr/share/webmin/changepass.pl /etc/webmin root "$webmin_password")
                    isSuccessful "Password changed and Webmin restarted successfully."
                    break
                else
                    isNotice "Password is too short or empty. Please provide a password with at least 8 characters."
                fi
            done
        fi

        local result=$(sudo systemctl restart webmin)
        checkSuccess "Restarting Virtualminwebhost (Webmin)"

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Updating file permissions before starting."
        echo ""

        fixPermissionsBeforeStart $app_name;

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to Install $app_name"
        echo ""

        dockerUpdateAndStartApp $app_name install;

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Running Application specific updates (if required)"
        echo ""

        updateApplicationSpecifics $app_name;

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
        echo "    You can now navigate to your $app_name service using any of the options below : "
        echo ""
        echo "    Public : https://$host_setup/"
        echo "    External : http://$public_ip:$usedport1/"
        echo "    Local : http://$ip_setup:$usedport1/"
        echo ""    
        menu_number=0
        sleep 3s
        cd
    fi
    virtualminwebhost=n
}
