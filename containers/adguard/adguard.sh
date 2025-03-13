#!/bin/bash

# Category : system
# Description : Adguard - DNS Server (c/u/s/r/i):

installAdguard()
{
    if [[ "$adguard" == *[cCtTuUsSrRiI]* ]]; then
        dockerConfigSetupToContainer silent adguard;
        local app_name=$CFG_ADGUARD_APP_NAME
    	setupInstallVariables $app_name;
    fi

    if [[ "$adguard" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

    if [[ "$adguard" == *[uU]* ]]; then
        dockerUninstallApp $app_name;
    fi

    if [[ "$adguard" == *[sS]* ]]; then
        dockerComposeDown $app_name;
    fi

    if [[ "$adguard" == *[rR]* ]]; then
        dockerComposeRestart $app_name;
    fi

    if [[ "$adguard" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###          Install $app_name"
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
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		dockerComposeUpdateAndStartApp $app_name install;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Initial install started for $app_name"
        echo ""
        echo ""
		echo "    NOTICE : Setup is needed in order to get Adguard online"
        echo "    NOTICE : Below are the urls for the setup ONLY."
        echo "    NOTICE : You can press next x5 until the installation is complete."
        echo ""
        echo "    External : http://$public_ip_v4:$usedport1/"
        echo "    Local : http://$ip_setup:$usedport1/"
        echo ""
        echo "    NOTICE : Skip this setup if you have already installed Adguard"
        echo ""

        while true; do
            echo ""
            isNotice "Setup is now available, please follow the instructions above."
            echo ""
            isQuestion "Have you followed the instructions above? (y/n): "
            read -p "" adguard_instructions
            if [[ "$adguard_instructions" == 'y' || "$adguard_instructions" == 'Y' ]]; then
                break
            else
                isNotice "Please confirm the setup or provide a valid input."
            fi
        done

        #result=$(sudo sed -i "s/address: 0.0.0.0:80/address: 0.0.0.0:${usedport2}/g" "$containers_dir$app_name/conf/AdGuardHome.yaml")
        #checkSuccess "Changing port 80 to $usedport2 for Admin Panel"

        #result=$(sudo sed -i "s/port: 53/port: ${usedport3}/g" "$containers_dir$app_name/conf/AdGuardHome.yaml")
        #checkSuccess "Changing port 53 to $usedport3 for DNS Port"

        #result=$(sudo sed -i "s/port_https: 443/port_https: ${usedport4}/g" "$containers_dir$app_name/conf/AdGuardHome.yaml")
        #checkSuccess "Changing port 443 to $usedport4 for DNS Port"

        #result=$(sudo sed -i "s/port_dns_over_tls: 853/port_dns_over_tls: ${usedport5}/g" "$containers_dir$app_name/conf/AdGuardHome.yaml")
        #checkSuccess "Changing port 853 to $usedport5 for port_dns_over_tls"

        #result=$(sudo sed -i "s/port_dns_over_quic: 853/port_dns_over_quic: ${usedport5}/g" "$containers_dir$app_name/conf/AdGuardHome.yaml")
        #checkSuccess "Changing port 853 to $usedport5 for port_dns_over_quic"

        # Find the line number containing "tls:"
        local tls_line_number=$(sudo awk '/tls:/ {print NR; exit}' "$containers_dir$app_name/conf/AdGuardHome.yaml")
        # Check if "tls:" was found
        if [ -n "$tls_line_number" ]; then
            # Replace the next two lines
            sudo sed -i "$((tls_line_number + 1))s/.*/  enabled: true/" "$containers_dir$app_name/conf/AdGuardHome.yaml"
            sudo sed -i "$((tls_line_number + 2))s/.*/  server_name: \"$host_setup\"/" "$containers_dir$app_name/conf/AdGuardHome.yaml"
        fi
        checkSuccess "Enabling tls config options for encrypted DNS"

        if [[ $public == "true" ]]; then
            result=$(sudo sed -i "s|allow_unencrypted_doh: false|allow_unencrypted_doh: true|g" "$containers_dir$app_name/conf/AdGuardHome.yaml")
            checkSuccess "Setting allow_unencrypted_doh to false for Traefik"
        fi

        result=$(sudo sed -i "s|anonymize_client_ip: false: false|anonymize_client_ip: true|g" "$containers_dir$app_name/conf/AdGuardHome.yaml")
        checkSuccess "Setting anonymize_client_ip to true for privacy reasons"

        dockerComposeRestart "$app_name";

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
        echo "    You can now navigate to your $app_name service using any of the options below : "
        echo ""
        echo "    NOTICE : Below are the URLs for the admin panel to use after you have setup Adguard"
        echo ""
        
        menuShowFinalMessages $app_name "" "" $PORT2; 

		menu_number=0
        sleep 3s
        cd
    fi
    adguard=n
}