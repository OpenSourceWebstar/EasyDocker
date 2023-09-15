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

		databasePathInsert $initial_path;

		# Internet Test
		isNotice "Testing internet, please wait..."
		if sudo ping -c 4 "9.9.9.9" > /dev/null; then
			isSuccessful "Internet connectivity is working."
		else
			isError "Internet connectivity is not working."
			exit 1
		fi

		cd "$script_dir" || { echo "Error: Cannot navigate to the repository directory"; exit 1; }

		# Update Git to ignore changes in file permissions
		sudo -u $easydockeruser git config core.fileMode false
		# Update Git with email address
		sudo -u $easydockeruser git config --global user.name "$CFG_INSTALL_NAME"
		sudo -u $easydockeruser git config --global user.email "$CFG_EMAIL"

		# Check if there are uncommitted changes
		if [[ $(git status --porcelain) ]]; then
			isNotice "There are uncommitted changes in the repository."
			while true; do
				isQuestion "Do you want to discard these changes and update the repository? (y/n): "
				read -p "" customupdatesfound
				case $customupdatesfound in
					[yY])
						gitFolderResetAndBackup;
						fixFolderPermissions;
						sourceScripts $script_dir;

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
			fixFolderPermissions;
			sourceScripts $script_dir;

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
	databasePathInsert $initial_path_save
	if [[ $CFG_REQUIREMENT_MIGRATE == "true" ]]; then
		migrateCheckForMigrateFiles;
		migrateGenerateTXTAll;
		migrateScanFoldersForUpdates;
		migrateScanConfigsToMigrate;
		migrateScanMigrateToConfigs;
	fi
    #databaseSSHScanForKeys;
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

	if [[ "$migratescanforconfigstomigrate" == [yY] ]]; then
		migrateScanConfigsToMigrate;
	fi

	if [[ "$migratescanformigratetoconfigs" == [yY] ]]; then
		migrateScanMigrateToConfigs;
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
	resetToMenu;
}

exitScript() {
	echo ""
	echo ""
	isNotice "Exiting script..."
	isNotice "Goodbye <3..."
	echo ""
    if [ -f "$base_dir/$db_file" ]; then
        database_path=$(sqlite3 "$base_dir/$db_file" "SELECT path FROM path LIMIT 1;")
		isNotice "Last working path :"
		isNotice "cd $database_path"
    fi
	echo ""
	stty echo
	exit 0
}


# Start the script
checkUpdates;
