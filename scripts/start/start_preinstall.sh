#!/bin/bash

startPreInstall()
{
	# Disable Input
	# stty -echo
	
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
    installStandaloneWireGuard;
    
    #######################################################
    ###                   Install Docker                ###
    #######################################################

    # Rootless
    installDockerRootlessUser;
	installDockerRootlessStartSetup;

    installSSHKeysForDownload install;

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
