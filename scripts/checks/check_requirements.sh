#!/bin/bash

checkRequirements()
{  
	echo ""
	echo "#####################################"
	echo "###      Checking Requirements    ###"
	echo "#####################################"
	echo ""
	isNotice "Requirements are about to be installed."
	isNotice "Edit the config_requirements if you want to disable anything before starting."
	echo ""

	checkRootRequirement;
	checkCommandRequirement;
	checkWireguardRequirement;
	checkInstallTypeRequirement;
	checkConfigRequirement; 
	checkPasswordsRequirement;
	checkDatabaseRequirement;
	checkSSHKeysRequirement;
	checkDockerRequirement;
	checkDockerComposeRequirement;
	checkDockerRootlessRequirement;
	checkDockerNetworkRequirement;
	checkUFWRequirement;
	checkUFWDRequirement;
	checkManagerRequirement;
	checkSSLCertsRequirement;
	checkSwapfileRequirement;
	checkCrontabRequirement;
	checkSSHRemoteRequirement;
	checkSuggestInstallsRequirement;
	checkSSHDownloadRequirement;
	checkSSHPasswordRequirement;
	checkTraefikRequirement;
	checkDockerSwitcherRequirement;

	if [[ "$preinstallneeded" -ne 0 ]]; then
		startPreInstall;
	fi

	startScan;
	resetToMenu;
} 