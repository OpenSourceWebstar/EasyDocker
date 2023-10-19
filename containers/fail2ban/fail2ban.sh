#!/bin/bash

# Category : system
# Description : Fail2Ban - Connection Security (c/u/s/r/i):

installFail2ban()
{
    local passedValue="$1"

    if [[ "$passedValue" == "install" ]]; then
        fail2ban=i
    fi

    if [[ "$fail2ban" == *[cCtTuUsSrRiI]* ]]; then
        setupConfigToContainer --silent fail2ban;
        local app_name=$CFG_FAIL2BAN_APP_NAME
		setupInstallVariables $app_name;
    fi

    if [[ "$fail2ban" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

    if [[ "$fail2ban" == *[uU]* ]]; then
        uninstallApp $app_name;
    fi

    if [[ "$fail2ban" == *[sS]* ]]; then
        shutdownApp $app_name;
    fi

    if [[ "$fail2ban" == *[rR]* ]]; then
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
        echo "---- $menu_number. Setting up install folder and config file for $app_name."
        echo ""

        setupConfigToContainer $app_name install;
        isSuccessful "Install folders and Config files have been setup for $app_name."

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

		fixPermissionsBeforeStart $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Setting up AbuseIPDB for fail2ban if api key is provided"
        echo ""

        if [ -n "$CFG_FAIL2BAN_ABUSEIPDB_APIKEY" ]; then
            checkSuccess "API key found, setting up the config file."

            local result=$(mkdirFolders $containers_dir$app_name/logs)
            checkSuccess "Creating logs folder"

            local result=$(cd $containers_dir$app_name && createTouch $containers_dir$app_name/logs/auth.log)
            checkSuccess "Creating Auth.log file"

            local result=$(mkdirFolders $containers_dir$app_name/config/$app_name $containers_dir$app_name/config/$app_name/action.d)
            checkSuccess "Creating config and action.d folders"

            # AbuseIPDB
            local result=$(cd $containers_dir$app_name/config/$app_name/action.d/ && sudo curl -o abuseipdb.conf https://raw.githubusercontent.com/fail2ban/fail2ban/0.11/config/action.d/abuseipdb.conf)
            checkSuccess "Downloading abuseipdb.conf from GitHub"
            
            local result=$(sudo sed -i "s/abuseipdb_apikey =/abuseipdb_apikey =$CFG_FAIL2BAN_ABUSEIPDB_APIKEY/g" $containers_dir$app_name/config/$app_name/action.d/abuseipdb.conf)
            checkSuccess "Setting up abuseipdb_apikey"

            # Jail.local
            local result=$(mkdirFolders $containers_dir$app_name/config/$app_name/)
            checkSuccess "Creating $app_name folder"

		    local result=$(copyResource "$app_name" "jail.local" "config/$app_name/jail.local" | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" 2>&1)
            checkSuccess "Coping over jail.local from Resources folder"

            local result=$(sudo sed -i "s/my-api-key/$CFG_FAIL2BAN_ABUSEIPDB_APIKEY/g" $containers_dir$app_name/config/$app_name/jail.local)
            checkSuccess "Setting up AbuseIPDB API Key in jail.local file"
        else
            isNotice "No API key found, please provide one if you want to use AbuseIPDB"
        fi

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		whitelistAndStartApp $app_name install;

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Checking & Opening ports if required"
        echo ""

        checkAppPorts $app_name $port $port_2;

		((menu_number++))
		echo ""
        echo "---- $menu_number. Adding $app_name to the Apps Database table."
        echo ""

		databaseInstallApp $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. You can find $app_name files at $containers_dir$app_name"
        echo ""
        echo "    Your $app_name service is now online!"
        echo ""

		menu_number=0
        sleep 3s
        cd
    fi
    fail2ban=n
}