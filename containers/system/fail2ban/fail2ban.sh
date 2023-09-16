#!/bin/bash

# Description : Fail2Ban - Connection Security

installFail2Ban()
{
	app_name=$CFG_FAIL2BAN_APP_NAME

    if [[ "$fail2ban" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

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

        if [ -n "$CFG_FAIL2BAN_ABUSEIPDB_APIKEY" ]; then
            checkSuccess "API key found, setting up the config file."

            result=$(cd $install_path$app_name && createTouch $install_path$app_name/logs/auth.log)
            checkSuccess "Creating Auth.log file"

            result=$(mkdirFolders $install_path$app_name/config/$app_name $install_path$app_name/config/$app_name/action.d)
            checkSuccess "Creating config and action.d folders"

            # AbuseIPDB
            result=$(cd $install_path$app_name/config/$app_name/action.d/ && sudo curl -o abuseipdb.conf https://raw.githubusercontent.com/fail2ban/fail2ban/0.11/config/action.d/abuseipdb.conf)
            checkSuccess "Downloading abuseipdb.conf from GitHub"
            
            result=$(sudo sed -i "s/abuseipdb_apikey =/abuseipdb_apikey =$CFG_FAIL2BAN_ABUSEIPDB_APIKEY/g" $install_path$app_name/config/$app_name/action.d/abuseipdb.conf)
            checkSuccess "Setting up abuseipdb_apikey"

            # Jail.local
		    result=$(copyResource "jail.local" "config/$app_name/jail.local" | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" 2>&1)
            checkSuccess "Coping over jail.local from Resources folder"

            result=$(sudo sed -i "s/my-api-key/$CFG_FAIL2BAN_ABUSEIPDB_APIKEY/g" $install_path$app_name/config/$app_name/jail.local)
            checkSuccess "Setting up AbuseIPDB API Key in jail.local file"

            result=$(sudo sed -i "s/ips_whitelist/$CFG_IPS_WHITELIST/g" $install_path$app_name/config/$app_name/jail.local)
            checkSuccess "Setting up IP Whitelist in jail.local file"

		    dockerDownUpDefault;
        else
            isNotice "No API key found, please provide one if you want to use AbuseIPDB"
        fi

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Opening ports if required"
        echo ""

        openAppPorts;

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