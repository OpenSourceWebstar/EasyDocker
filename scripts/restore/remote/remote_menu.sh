#!/bin/bash

restoreRemoteMenu()
{
    local backup_type="$1"

    checkRemoteBackupEnabled;
    
    if [[ $remote_backups_disabled == "true" ]]; then
        isNotice "Remote backups have not been set up."
        while true; do
            read -rp "Remote backups are not configured. Do you want to edit the backup configuration now? (Y/N): " remotebackupsetup
            case "$remotebackupsetup" in
                [Yy]) 
                    viewEasyDockerConfigs "backup"
                    sourceScanFiles "easydocker_configs"
                    break
                    ;;
                [Nn]) 
                    isNotice "Skipping backup configuration."
                    break
                    ;;
                *) 
                    isNotice "Invalid input. Please enter 'Y' or 'N'."
                    ;;
            esac
        done
    elif [[ $remote_backups_disabled == "false" ]]; then
        selectRemoteLocation;
        selectRemoteInstallName;
    fi

    selectRemoteApp
}
