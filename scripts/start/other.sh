#!/bin/bash

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
