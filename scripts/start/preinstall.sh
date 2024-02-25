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

    # Rootless
    installDockerRootlessUser;
	installDockerRootlessSetup;

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
