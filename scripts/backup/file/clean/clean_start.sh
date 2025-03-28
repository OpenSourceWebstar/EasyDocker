#!/bin/bash

# Function to clean backups (local or remote)
backupCleanFiles() 
{
    # Safeguarding
    if [ -z "$app_name" ]; then
        isNotice "Empty app_name, something went wrong"
        exit 1
    fi

    # Clean local backups if specified
    if [ "$CFG_BACKUP_KEEPDAYS" != "0" ]; then
        isNotice "Starting local backup cleanup..."
        clean_local_backups "$backup_save_directory"
    fi

    # Clean remote backups for remote server 1 if flag is set
    if [ "$CFG_BACKUP_REMOTE_1_BACKUP_CLEAN" == "true" ] && [ "$CFG_BACKUP_REMOTE_1_ENABLED" == "true" ]; then
        isNotice "Starting remote backup cleanup for server 1..."
        clean_remote_backups "$CFG_BACKUP_REMOTE_1_IP" "$CFG_BACKUP_REMOTE_1_USER" \
                             "$CFG_BACKUP_REMOTE_1_PASS" "$CFG_BACKUP_REMOTE_1_PORT" \
                             "$CFG_BACKUP_REMOTE_1_BACKUP_DIRECTORY" "$CFG_BACKUP_REMOTE_1_BACKUP_KEEPDAYS"
    fi

    # Clean remote backups for remote server 2 if flag is set
    if [ "$CFG_BACKUP_REMOTE_2_BACKUP_CLEAN" == "true" ] && [ "$CFG_BACKUP_REMOTE_2_ENABLED" == "true" ]; then
        isNotice "Starting remote backup cleanup for server 2..."
        clean_remote_backups "$CFG_BACKUP_REMOTE_2_IP" "$CFG_BACKUP_REMOTE_2_USER" \
                             "$CFG_BACKUP_REMOTE_2_PASS" "$CFG_BACKUP_REMOTE_2_PORT" \
                             "$CFG_BACKUP_REMOTE_2_BACKUP_DIRECTORY" "$CFG_BACKUP_REMOTE_2_BACKUP_KEEPDAYS"
    fi
}
