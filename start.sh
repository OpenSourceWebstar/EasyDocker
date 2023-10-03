#!/bin/bash

# Used for saving directory path
initial_path="$3"
initial_path_save=$initial_path

sourceScript() 
{
    local script_file="$1"

    if [ -f "$script_file" ]; then
        source "$script_file"
    else
        echo "Error: '$script_file' not found."
        exit 1
    fi

    local missing_files=()
    while read -r line; do
        local file=$(echo "$line" | awk -F ' ' '{print $NF}' | sed 's/[";]//g')
        if [ -n "$file" ] && [ ! -f "$file" ]; then
            missing_files+=("$file")
        fi
    done < <(grep 'source ' "$script_file")

    if [ ${#missing_files[@]} -gt 0 ]; then
        echo ""
        echo "####################################################"
        echo "###       Missing EasyDocker Install Files       ###"
        echo "####################################################"
        echo ""
        for missing_file in "${missing_files[@]}"; do
            echo "NOTICE : It seems that $missing_file is missing from your EasyDocker Installation."
        done
        echo ""
        echo "OPTION : 1. Reinstall EasyDocker"
        echo "OPTION : 2. Continue...*NOT RECOMMENDED*"
        echo "OPTION : x. Exit"
        echo ""
        read -rp "Enter your choice (1 or 2) or 'x' to skip : " choice
        case "$choice" in
            1)
                runInitReinstall;
            ;;
            2)
                # User chose to continue
            ;;
            [xX])
                # User chose to exit
                exit 1
            ;;
            *)
                echo "Invalid choice. Please enter 1, 2, or 'x'."
            ;;
        esac
    fi

    # Call the function to check for updates
    checkUpdates;
}

runInitReinstall() 
{
    sudo bash -c 'cd ~ && rm -rf init.sh && apt-get install wget -y && wget -O init.sh https://raw.githubusercontent.com/OpenSourceWebstar/EasyDocker/main/init.sh && chmod 0755 init.sh && ./init.sh run'
}

# Call the function to source the script
sourceScript "scripts/sources.sh"

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
	fi
    #databaseSSHScanForKeys;
    scanConfigsForRandomPassword;
	dashyUpdateConf;
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

    #######################################################
    ###                Install System Apps              ###
    #######################################################

    installFail2ban;
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

	installSearxng;
    installSpeedtest;
	installIpinfo;
	installCozy;
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
    if [ -f "$docker_dir/$db_file" ]; then
        database_path=$(sqlite3 "$docker_dir/$db_file" "SELECT path FROM path LIMIT 1;")
		isNotice "Last working path :"
		isNotice "cd $database_path"
    fi
	echo ""
	stty echo
	exit 0
}
