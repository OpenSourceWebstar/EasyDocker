#!/bin/bash

startScan()
{
	databasePathInsert $initial_path_save;
    # To update the configs
	sourceScanFiles "easydocker_configs";
    sourceScanFiles "app_configs";
    sourceScanFiles "containers";
    portClearAllData;
	if [[ $CFG_REQUIREMENT_MIGRATE == "true" ]]; then
		migrateCheckForMigrateFiles;
		migrateGenerateTXTAll;
		migrateScanFoldersForUpdates;
	fi
    scanConfigsForRandomPassword;
    updateDockerInstallPassword;
	appDashyUpdateConf;
	if [[ $CFG_REQUIREMENT_DNS_UPDATER == "true" ]]; then
        updateDNS "" scan;
    fi
	if [[ $CFG_REQUIREMENT_WHITELIST_PORT_UPDATER == "true" ]]; then
		dockerScan;
    fi
    databaseAppScan;
    databaseCycleThroughListAppsCrontab "false";
    databaseListInstalledApps;
}
