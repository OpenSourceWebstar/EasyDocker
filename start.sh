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
    if [[ "$traefik_status" == "installed" ]] then;
        traefikSetupLoginCredentials;
    fi
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

    #######################################################
    ###                   Install Docker                ###
    #######################################################

    installDockerUser;
	installDocker;
    installDockerCompose;
    installDockerCheck;
	installDockerRootless;
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

    installSSHKeysForDownload install;
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
    local wireguard_status=$(checkAppInstalled "wireguard" "docker")
    if [[ "$traefik_status" != "installed" || "$wireguard_status" != "installed" ]]; then
        echo ""
        echo "####################################################"
        echo "###           Recommended Applications           ###"
        echo "####################################################"
        echo ""
        isNotice "It's recommended to install both Traefik & Wiregard upon first install."
        echo ""
        isNotice "Traefik secures your Network traffic and automatically installs SSL Certificates"
        isNotice "Wireguard allows remote VPN access into your docker network"
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

            # Wireguard
            if [[ "$wireguard_status" != "installed" ]]; then
                wireguard=i
                installWireguard;
            fi

            isSuccessful "All recommended apps have successfully been set up."
        elif [[ "$recommendation_choice" == [nN] ]]; then
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
    clearAllPortData;
	if [[ $CFG_REQUIREMENT_MIGRATE == "true" ]]; then
		migrateCheckForMigrateFiles;
		migrateGenerateTXTAll;
		migrateScanFoldersForUpdates;
	fi
    #databaseSSHScanForKeys;
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
    ###                Install System Apps              ###
    #######################################################

    installAdguard;
    installAuthelia;
    installDashy;
    installDuplicati;
    installFail2ban;
    installGrafana;
    installHeadscale;
    installPihole;
    installPortainer;
    installPrometheus;
    installTraefik;
    #installVirtualminadmin;
    #installVirtualminwebhost;
    installWatchtower;
    installWireguard;

    #######################################################
    ###                Install Privacy Apps             ###
    #######################################################

	installSearxng;
    installSpeedtest;
	installInvidious;
	installIpinfo;
	installTrilium;
    installMailcow;
	installVaultwarden;

    #######################################################
    ###                 Install User Apps               ###
    #######################################################

	installTiledesk;
	installGitlab;
	installOwncloud;
	installJitsimeet;
	installKillbill;
    installRustdesk;
	installActual;
    installKimai;
	installMattermost;

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