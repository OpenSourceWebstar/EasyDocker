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

	installDockerManagerUser;
    installSSHRemoteList;

    installSSLCertificate;
    installSwapfile;
    

    startScan;
	resetToMenu;
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
	dashyUpdateConf;
	if [[ $CFG_REQUIREMENT_DNS_UPDATER == "true" ]]; then
        updateDNS;
    fi
	if [[ $CFG_REQUIREMENT_WHITELIST_PORT_UPDATER == "true" ]]; then
		whitelistScan;
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

    installAdguard
    installAuthelia
    installCaddy
    installDashy
    installDuplicati;
    installFail2ban;
    installGrafana;
    installHeadscale;
    installPihole;
    installPortainer;
    installPrometheus;
    installTraefik;
    installVirtualmin;
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

	if [[ "$toolsresetgit" == [yY] ]]; then
		gitFolderResetAndBackup;
	fi

	if [[ "$toolstartpreinstallation" == [yY] ]]; then
		startPreInstall;
	fi

	if [[ "$toolsstartcrontabsetup" == [yY] ]]; then
		databaseCycleThroughListAppsCrontab
	fi

	if [[ "$toolrestartcontainers" == [yY] ]]; then
		dockerStartAllApps;
	fi

	if [[ "$toolstopcontainers" == [yY] ]]; then
		dockerStopAllApps;
	fi

    if [[ "$toolsremovedockermanageruser" == [yY] ]]; then
		uninstallDockerManagerUser;
	fi

    if [[ "$toolsinstalldockermanageruser" == [yY] ]]; then
		installDockerManagerUser;
	fi

    if [[ "$toolinstallremotesshlist" == [yY] ]]; then
        installSSHRemoteList;
    fi

    if [[ "$toolinstallcrontab" == [yY] ]]; then
        installCrontab
    fi

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