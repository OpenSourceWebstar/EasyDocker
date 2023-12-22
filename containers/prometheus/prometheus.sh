#!/bin/bash

# Category : system
# Description : Prometheus - Metrics Collector (c/u/s/r/i):

installPrometheus()
{
    if [[ "$prometheus" == *[cCtTuUsSrRiI]* ]]; then
        setupConfigToContainer silent prometheus;
        local app_name=$CFG_PROMETHEUS_APP_NAME
		setupInstallVariables $app_name;
    fi

    if [[ "$prometheus" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

	if [[ "$prometheus" == *[uU]* ]]; then
		uninstallApp $app_name;
	fi

	if [[ "$prometheus" == *[sS]* ]]; then
		shutdownApp $app_name;
	fi

	if [[ "$prometheus" == *[rR]* ]]; then
        dockerDownUp $app_name;
	fi

    if [[ "$prometheus" == *[iI]* ]]; then
        echo ""
        echo "##########################################"
        echo "###           Install $app_name"
        echo "##########################################"
        echo ""
        
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

        local result=$(mkdirFolders "loud" $CFG_DOCKER_INSTALL_USER "$containers_dir$app_name/$app_name")
        checkSuccess "Created $app_name folder in $app_name"

        local result=$(createTouch "$containers_dir$app_name/$app_name/$app_name.yml" $CFG_DOCKER_INSTALL_USER)
        checkSuccess "Created $app_name.yml file for $app_name"

		local result=$(copyResource "$app_name" "$app_name.yml" "$app_name" | sudo -u $sudo_user_name tee -a "$logs_dir/$docker_log_file" 2>&1)
		checkSuccess "Copying $app_name.yml to containers folder."

		((menu_number++))
        echo ""
        echo "---- $menu_number. Updating file permissions before starting."
        echo ""

		fixPermissionsBeforeStart $app_name;

		((menu_number++))
        echo ""
        echo "---- $menu_number. Running the docker-compose.yml to install and start $app_name"
        echo ""

		dockerUpdateAndStartApp $app_name install;

        # Prometheus
        if [ -f "${containers_dir}prometheus/prometheus/prometheus.yml" ]; then
            updateFileOwnership "${containers_dir}prometheus/prometheus/prometheus.yml" $CFG_DOCKER_INSTALL_USER $CFG_DOCKER_INSTALL_USER
        fi
        if [ -d "${containers_dir}prometheus/prometheus" ]; then
            local result=$(sudo chmod -R 777 "${containers_dir}prometheus/prometheus")
            checkSuccess "Set permissions to prometheus folder."
        fi
        if [ -d "${containers_dir}prometheus/prom_data" ]; then
            local result=$(sudo chmod -R 777 "${containers_dir}prometheus/prom_data")
            checkSuccess "Set permissions to prom_data folder."
        fi

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
        
        menuShowFinalMessages $app_name;
		      
		menu_number=0
        sleep 3s
        cd
    fi
    prometheus=n
}