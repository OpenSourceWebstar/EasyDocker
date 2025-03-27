#!/bin/bash

selectRemoteLocation()
{
    # If a remote number (1 or 2) is passed, validate it and set the remote details
    if [ -n "$1" ]; then
        case "$1" in
            1)
                if [ "${CFG_BACKUP_REMOTE_1_ENABLED}" != "true" ]; then
                    isError "Remote Backup Server 1 is disabled. Cannot proceed."
                    return 1
                fi
                remote_user="${CFG_BACKUP_REMOTE_1_USER}"
                remote_ip="${CFG_BACKUP_REMOTE_1_IP}"
                remote_port="${CFG_BACKUP_REMOTE_1_PORT}"
                remote_pass="${CFG_BACKUP_REMOTE_1_PASS}"
                remote_directory="${CFG_BACKUP_REMOTE_1_BACKUP_DIRECTORY}"
                remote_server=1
                ;;
            2)
                if [ "${CFG_BACKUP_REMOTE_2_ENABLED}" != "true" ]; then
                    isError "Remote Backup Server 2 is disabled. Cannot proceed."
                    return 1
                fi
                remote_user="${CFG_BACKUP_REMOTE_2_USER}"
                remote_ip="${CFG_BACKUP_REMOTE_2_IP}"
                remote_port="${CFG_BACKUP_REMOTE_2_PORT}"
                remote_pass="${CFG_BACKUP_REMOTE_2_PASS}"
                remote_directory="${CFG_BACKUP_REMOTE_2_BACKUP_DIRECTORY}"
                remote_server=2
                ;;
            *)
                isError "Invalid remote backup selection: $1"
                return 1
                ;;
        esac
    fi

    # Interactive Mode (unchanged from original)
    while true; do
        echo ""
        isNotice "Please select a remote backup location"
        isNotice "TIP: These are defined in the config_backup file."
        echo ""
        
        if [ "${CFG_BACKUP_REMOTE_1_ENABLED}" == "true" ]; then
            isOption "1. Backup Server 1 - '$CFG_BACKUP_REMOTE_1_USER'@'$CFG_BACKUP_REMOTE_1_IP' (Enabled)"
        else
            isOption "1. Backup Server 1 (Disabled)"
        fi
        
        if [ "${CFG_BACKUP_REMOTE_2_ENABLED}" == "true" ]; then
            isOption "2. Backup Server 2 - '$CFG_BACKUP_REMOTE_2_USER'@'$CFG_BACKUP_REMOTE_2_IP' (Enabled)"
        else
            isOption "2. Backup Server 2 (Disabled)"
        fi
        
        echo ""
        isOption "x. Exit"
        echo ""
        isQuestion "Enter your choice: "
        read -rp "" select_remote

        case "$select_remote" in
            1)
                if [ "${CFG_BACKUP_REMOTE_1_ENABLED}" != "true" ]; then
                    isError "Remote Backup Server 1 is disabled. Cannot proceed."
                    return 1
                fi
                remote_user="${CFG_BACKUP_REMOTE_1_USER}"
                remote_ip="${CFG_BACKUP_REMOTE_1_IP}"
                remote_port="${CFG_BACKUP_REMOTE_1_PORT}"
                remote_pass="${CFG_BACKUP_REMOTE_1_PASS}"
                remote_directory="${CFG_BACKUP_REMOTE_1_BACKUP_DIRECTORY}"
                remote_server=1
                return 0
                ;;
            2)
                if [ "${CFG_BACKUP_REMOTE_2_ENABLED}" != "true" ]; then
                    isError "Remote Backup Server 2 is disabled. Cannot proceed."
                    return 1
                fi
                remote_user="${CFG_BACKUP_REMOTE_2_USER}"
                remote_ip="${CFG_BACKUP_REMOTE_2_IP}"
                remote_port="${CFG_BACKUP_REMOTE_2_PORT}"
                remote_pass="${CFG_BACKUP_REMOTE_2_PASS}"
                remote_directory="${CFG_BACKUP_REMOTE_2_BACKUP_DIRECTORY}"
                remote_server=2
                return 0
                ;;
            x|X)
                isNotice "Exiting..."
                resetToMenu;
                ;;
            *)
                isNotice "Invalid option. Please select a valid option."
                continue
                ;;
        esac
    done
}
