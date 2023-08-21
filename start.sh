#!/bin/bash

source scripts/sources.sh

startPreInstall()
{
	# Disable Input
	stty -echo
	
    echo ""
    echo "#######################################################"
    echo "###               Pre-Installation                  ###"
    echo "#######################################################"
    echo ""

    #######################################################
    ###          Install for Operating System           ###
    #######################################################

    installDebianUbuntu;
    installArch;

    #######################################################
    ###                   Install Docker                ###
    #######################################################

    installDockerUser;
    installDockerCompose;
    installDockerCheck;
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
	mainMenu;
}

startScan()
{
    databaseSSHScanForKeys;
    scanConfigsForRandomPassword;
    databaseAppScan;
    databaseListInstalledApps;
    databaseCycleThroughListAppsCrontab;
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

    #######################################################
    ###                Install System Apps              ###
    #######################################################

    installFail2Ban;
    installCaddy;
    installTraefik;
    installWireguard;
	installAdguard;
    installPihole;
	installPortainer;
    installWatchtower;
	installDashy;
    installDuplicati;

    #######################################################
    ###                Install Privacy Apps             ###
    #######################################################

	installSearXNG;
    installSpeedtest;
	installIPInfo;
	installCozy;
	installTrilium;
    installMailcow;
	installVaultwarden;

    #######################################################
    ###                 Install User Apps               ###
    #######################################################

	installTileDesk;
	installGitLab;
	installOwnCloud;
	installJitsiMeet;
	installKillbill;
	installActual;
    installAkaunting;
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

    #######################################################
    ###                     Tools                    ###
    #######################################################
	if [[ "$toolsupdategit" == [yY] ]]; then
		updateGit;
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

    if [[ "$toolinstallcrontabssh" == [yY] ]]; then
        installCrontabSSHScan;
    fi

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

    completeMessage;
    checkRequirements;
	mainMenu;
}

exitScript() {
	echo ""
	echo ""
	isNotice "Exiting script..."
	echo ""
	isNotice "Last working path :"
	isNotice "cd $initial_path_save"
	echo ""
	exit 0
}

# Start the script
detectOS;

