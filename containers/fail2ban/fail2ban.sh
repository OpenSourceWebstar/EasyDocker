#!/bin/bash

# Category : system
# Description : Fail2Ban - Connection Security (c/u/s/r/i):

installFail2Ban()
{
    if [[ -n "$fail2ban" && "$fail2ban" =~ [a-zA-Z] ]]; then
        setupConfigToContainer fail2ban;
        app_name=$CFG_FAIL2BAN_APP_NAME
    fi

    if [[ "$fail2ban" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

    if [[ "$fail2ban" == *[uU]* ]]; then
        uninstallApp $app_name;
    fi

    if [[ "$fail2ban" == *[sS]* ]]; then
        shutdownApp;
    fi

    if [[ "$fail2ban" == *[rR]* ]]; then
		setupInstallVariables $app_name;
        if [[ $compose_setup == "default" ]]; then
		    dockerDownUpDefault $app_name;
        elif [[ $compose_setup == "app" ]]; then
            dockerDownUpAdditionalYML $app_name;
        fi
    fi

    if [[ "$fail2ban" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###     Install $app_name"
        echo "##########################################"
        echo ""
    
		((menu_number++))
        echo ""
        echo "---- $menu_number. Checking custom DNS entry and IP for setup"
        echo ""

		setupInstallVariables $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Pulling a default $app_name docker-compose.yml file."
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

		fixPermissionsBeforeStart;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		whitelistAndStartApp $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Setting up AbuseIPDB for fail2ban if api key is provided"
        echo ""

        if [ -n "$CFG_FAIL2BAN_ABUSEIPDB_APIKEY" ]; then
            checkSuccess "API key found, setting up the config file."

            result=$(cd $install_dir$app_name && createTouch $install_dir$app_name/logs/auth.log)
            checkSuccess "Creating Auth.log file"

            result=$(mkdirFolders $install_dir$app_name/config/$app_name $install_dir$app_name/config/$app_name/action.d)
            checkSuccess "Creating config and action.d folders"

            # AbuseIPDB
            result=$(cd $install_dir$app_name/config/$app_name/action.d/ && sudo curl -o abuseipdb.conf https://raw.githubusercontent.com/fail2ban/fail2ban/0.11/config/action.d/abuseipdb.conf)
            checkSuccess "Downloading abuseipdb.conf from GitHub"
            
            result=$(sudo sed -i "s/abuseipdb_apikey =/abuseipdb_apikey =$CFG_FAIL2BAN_ABUSEIPDB_APIKEY/g" $install_dir$app_name/config/$app_name/action.d/abuseipdb.conf)
            checkSuccess "Setting up abuseipdb_apikey"

            # Jail.local
		    result=$(copyResource "$app_name" "jail.local" "config/$app_name/jail.local" | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" 2>&1)
            checkSuccess "Coping over jail.local from Resources folder"

            result=$(sudo sed -i "s/my-api-key/$CFG_FAIL2BAN_ABUSEIPDB_APIKEY/g" $install_dir$app_name/config/$app_name/jail.local)
            checkSuccess "Setting up AbuseIPDB API Key in jail.local file"

            if [[ $compose_setup == "default" ]]; then
                dockerDownUpDefault $app_name;
            elif [[ $compose_setup == "app" ]]; then
                dockerDownUpAdditionalYML $app_name;
            fi
        else
            isNotice "No API key found, please provide one if you want to use AbuseIPDB"
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
        echo "    Your $app_name service is now online!"
        echo ""

		menu_number=0
        sleep 3s
        cd
    fi
    fail2ban=n
}