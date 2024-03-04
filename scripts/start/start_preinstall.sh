#!/bin/bash

startPreInstall()
{
	# Disable Input
	stty -echo
	
    echo ""
    echo "#######################################################"
    echo "###               Pre-Installation                  ###"
    echo "#######################################################"
    echo ""

    portClearAllData;

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

    # Rootless
    installDockerRootlessUser;
	installDockerRootlessStartSetup;

    # Rooted
	installDockerRooted;
    installDockerRootedCompose;
    installDockerRootedCheck;

    # Both
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

    installSSLCertificate;
    installSwapfile;

    startScan;

    #######################################################
    ###                    Recommended                  ###
    #######################################################

    installRecommendedApps;

	resetToMenu;
}
