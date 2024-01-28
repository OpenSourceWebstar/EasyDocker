#!/bin/bash

# Used for saving directory path
initial_path="$3"
initial_path_save=$initial_path

displayEasyDockerLogo() 
{
    echo "
____ ____ ____ _   _    ___  ____ ____ _  _ ____ ____ 
|___ |__| [__   \_/     |  \ |  | |    |_/  |___ |__/ 
|___ |  | ___]   |      |__/ |__| |___ | \_ |___ |  \ "
}

# Used to load any functions after update
startUp()
{
    installDockerUser;
    scanConfigsForRandomPassword;
	local traefik_status=$(checkAppInstalled "traefik" "docker")
    if [[ "$traefik_status" == "installed" ]]; then
        traefikSetupLoginCredentials;
    fi
	local sshdownload_status=$(checkAppInstalled "sshdownload" "docker")
    if [[ "$sshdownload_status" == "installed" ]]; then
        while true; do
            echo ""
            echo "##########################################"
            echo "###        SSH SECURITY WARNING        ###"
            echo "##########################################"
            echo ""
            isNotice "The SSH Download download service is currently online."
            isNotice "This is potentially DANGEROUS as it's accessable via anyone on the VPN"
            isNotice "We highly recommend uninstalling this service after downloading the SSH keys"
            isNotice "If you need to access this again, you can install it via the system install option"
            echo ""
            isQuestion "Would like to destroy the SSH Download service for security purposes? (y/n): "
            read -p "" ssh_download_uninstall
            if [[ -n "$ssh_download_uninstall" ]]; then
                break
            fi
            isNotice "Please provide a valid input."
        done
        if [[ "$ssh_download_uninstall" == [yY] ]]; then
            uninstallApp sshdownload;
        fi
    fi
    dockerSwitchBetweenRootAndRootless;
    checkRequirements;
}

startPreInstall()
{
	# Disable Input
	stty -echo
	
    echo ""
    echo "#######################################################"
    echo "###               Pre-Installation                  ###"
    echo "#######################################################"
    echo ""

    clearAllPortData;

    #######################################################
    ###          Install for Operating System           ###
    #######################################################

    installDebianUbuntu;
    installArch;
    installSSHKeysForDownload install;
    installStandaloneWireGuard;
    
    #######################################################
    ###                   Install Docker                ###
    #######################################################

    installDockerUser;
	installDocker;
    installDockerCompose;
    installDockerCheck;
	installDockerRootlessSetup;
    installDockerNetwork;

    #######################################################
    ###                Install UFW Firewall             ###
    #######################################################

    installUFW;
    installUFWDocker;

    #######################################################
    ###                    Install Misc                 ###
    #######################################################

    installSQLiteDatabase;
    installCrontab;

	installDockerManagerUser;
    installSSHRemoteList;

    installSSLCertificate;
    installSwapfile;

    startScan;

    #######################################################
    ###                    Recommended                  ###
    #######################################################

    installRecommendedApps;

	resetToMenu;
}

installRecommendedApps()
{
    local traefik_status=$(checkAppInstalled "traefik" "docker")
    if [[ "$traefik_status" != "installed" ]]; then
        echo ""
        echo "####################################################"
        echo "###           Recommended Applications           ###"
        echo "####################################################"
        echo ""
        isNotice "It's recommended to install Traefik upon first install."
        echo ""
        isNotice "Traefik secures your Network traffic and automatically installs SSL Certificates"
        echo ""
        while true; do
            isQuestion "Would you like to follow the recommendations? (y/n): "
            read -p "" recommendation_choice
            if [[ -n "$recommendation_choice" ]]; then
                break
            fi
            isNotice "Please provide a valid input."
        done
        if [[ "$recommendation_choice" == [yY] ]]; then
            # Traefik
            if [[ "$traefik_status" != "installed" ]]; then
                traefik=i
                installTraefik;
            fi

            isSuccessful "All recommended apps have successfully been set up."
        elif [[ "$recommendation_choice" == [nN] ]]; then
            local general_config_file="$configs_dir$config_file_general"
            result=$(sudo sed -i "s|CFG_REQUIREMENT_SUGGEST_INSTALLS=true|CFG_REQUIREMENT_SUGGEST_INSTALLS=false|" "$general_config_file")
            checkSuccess "Disabling install recommendations in the requirements config."
            isNotice "You can re-enable this in the requirements config file"
            loadFiles "easydocker_configs";
        fi
    fi
}

startScan()
{
	databasePathInsert $initial_path_save;
    # To update the configs
	loadFiles "easydocker_configs";
    loadFiles "app_configs";
    loadFiles "containers";
    clearAllPortData;
	if [[ $CFG_REQUIREMENT_MIGRATE == "true" ]]; then
		migrateCheckForMigrateFiles;
		migrateGenerateTXTAll;
		migrateScanFoldersForUpdates;
	fi
    #databaseSSHScanForKeys;
    #dockerUpdateAppsToDockerType;
    scanConfigsForRandomPassword;
    updateDockerInstallPassword;
	dashyUpdateConf;
	if [[ $CFG_REQUIREMENT_DNS_UPDATER == "true" ]]; then
        updateDNS "" scan;
    fi
	if [[ $CFG_REQUIREMENT_DOCKER_NETWORK_PRUNE == "true" ]]; then
        dockerPruneNetworks;
    fi
	if [[ $CFG_REQUIREMENT_WHITELIST_PORT_UPDATER == "true" ]]; then
		dockerScan;
    fi
    databaseAppScan;
    databaseListInstalledApps;
    databaseCycleThroughListAppsCrontab "false";

}

startInstall() 
{
	# Disable Input
	stty -echo

    echo ""
    echo "#######################################################"
    echo "###                Starting Setup                   ###"
    echo "#######################################################"
    echo ""

    clearAllPortData;

    #######################################################
    ###                    Install Apps                 ###
    #######################################################

    for install_app_name in "$install_containers_dir"/*/; do
        install_app_name=$(basename "$install_app_name")
        function_name_capitalized="$(tr '[:lower:]' '[:upper:]' <<< "${install_app_name:0:1}")${install_app_name:1}"

        if [ "$(type -t "install${function_name_capitalized}")" = "function" ]; then
            "install${function_name_capitalized}"
        fi
    done

	endStart;

}

startOther()
{
    #######################################################
    ###            Backup / Restore / Migrate           ###
    #######################################################

	restoreInitialize;
	databaseCycleThroughListApps;

	if [[ "$migratecheckforfiles" == [yY] ]]; then
		migrateCheckForMigrateFiles;
	fi

	if [[ "$migratemovefrommigrate" == [yY] ]]; then
		migrateRestoreFileMoveFromMigrate;
	fi

	if [[ "$migrategeneratetxt" == [yY] ]]; then
		migrateGenerateTXTAll;
	fi

	if [[ "$migratescanforupdates" == [yY] ]]; then
		migrateScanFoldersForUpdates;
	fi

    #######################################################
    ###                     Tools                       ###
    #######################################################

	if [[ "$toolsetupsshkeys" == [yY] ]]; then
		installSSHKeysForDownload tool;
	fi

	if [[ "$toolsresetgit" == [yY] ]]; then
		gitFolderResetAndBackup;
	fi

	if [[ "$toolstartpreinstallation" == [yY] ]]; then
		startPreInstall;
	fi

	if [[ "$toolrestartcontainers" == [yY] ]]; then
		dockerStartAllApps;
	fi

	if [[ "$toolstopcontainers" == [yY] ]]; then
		dockerStopAllApps;
	fi

	if [[ "$toolsstartcrontabsetup" == [yY] ]]; then
		databaseCycleThroughListAppsCrontab
	fi

    if [[ "$toolinstallcrontab" == [yY] ]]; then
        installCrontab
    fi

    #if [[ "$toolsremovedockermanageruser" == [yY] ]]; then
		#uninstallDockerManagerUser;
	#fi

    #if [[ "$toolsinstalldockermanageruser" == [yY] ]]; then
		#installDockerManagerUser;
	#fi

    #if [[ "$toolinstallremotesshlist" == [yY] ]]; then
        #installSSHRemoteList;
    #fi

    #if [[ "$toolinstallcrontabssh" == [yY] ]]; then
        #installCrontabSSHScan;
    #fi

    #######################################################
    ###                      Database                   ###
    #######################################################

	databaseRemoveFile;
	databaseListAllApps;
	databaseDisplayTables;
	
	if [[ "$toollistinstalledapps" == [yY] ]]; then
		databaseListInstalledApps;
	fi

	if [[ "$toolupdatedb" == [yY] ]]; then
		databaseAppScan;
	fi

	databaseEmptyTable;

    #######################################################
    ###                     Headscale                   ###
    #######################################################

    headscaleCommands;

    if [[ "$headscaleconfigfile" == [yY] ]]; then
        headscaleEditConfig;
    fi

    #######################################################
    ###                     Firewall                    ###
    #######################################################

    firewallCommands;

	endStart;
}

endStart()
{
	#######################################################
    ###                   End Functions                 ###
    #######################################################

    clearAllPortData;
    completeMessage;
    checkRequirements;
	resetToMenu;
}

exitScript() 
{
	echo ""
	echo ""
	isNotice "Exiting script..."
	isNotice "Goodbye <3..."
	echo ""
    if [ -f "$docker_dir/$db_file" ]; then
        database_path=$(sqlite3 "$docker_dir/$db_file" "SELECT path FROM path LIMIT 1;")
		isNotice "Last working path :"
		isNotice "cd $database_path"
    fi
	echo ""
	stty echo
	exit 0
}

displayEasyDockerLogo;
source "scripts/sources.sh"