#!/bin/bash

# Used for saving directory path
initial_path="$3"
initial_path_save=$initial_path

source scripts/sources.sh

checkUpdates()
{
	if [[ $CFG_REQUIREMENT_UPDATES == "true" ]]; then
		echo ""
		echo "#####################################"
		echo "###      Checking for Updates     ###"
		echo "#####################################"
		echo ""

		# Attempt to download a file from the repository
		if curl --output /dev/null --silent --head --fail "$repo_url/README.md"; then
			checkSuccess "Repository is accessible network-wide."
		else
			checkSuccess "Repository is not accessible network-wide."
			exit 1
		fi

		cd "$script_dir" || { echo "Error: Cannot navigate to the repository directory"; exit 1; }

		result=$(git config core.fileMode false)
		checkSuccess "Update Git to ignore changes in file permissions"
		result=$(git config --global user.email "$CFG_EMAIL")
		checkSuccess "Update Git with email address"
		

		# Check if there are uncommitted changes
		if [[ $(git status --porcelain) ]]; then
			isNotice "There are uncommitted changes in the repository."
			while true; do
				isQuestion "Do you want to discard these changes and update the repository? (y/n): "
				read -p "" customupdatesfound
				case $customupdatesfound in
					[yY])
						gitFolderResetAndBackup;
						reloadScripts;

						isSuccessful "Starting/Restarting EasyDocker"
						detectOS;
						;;
					[nN])
						isNotice "Custom changes will be kept, continuing..."
                        detectOS;
						;;
					*)
						isNotice "Please provide a valid input (y or n)."
						;;
				esac
			done
		fi

		# Make sure an update happens after custom code check
		if [[ $update_done != "true" ]]; then
			gitFolderResetAndBackup;
			reloadScripts;

			isSuccessful "Starting/Restarting EasyDocker"
			detectOS;
		fi
	else
		detectOS;
	fi
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
checkUpdates;
